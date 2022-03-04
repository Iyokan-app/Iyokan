//
//  Serializer.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/06.
//

import Foundation
import AVFoundation
import os

fileprivate let serializationQueue = DispatchQueue(label: "org.iyokan-app.iyokan.serialization.queue", qos: .userInteractive)
fileprivate let logger = Logger.init(subsystem: "Iyokan", category: "Serializer")

// Only access via Player class
class Serializer: ObservableObject {
    static let shared = Serializer()

    private lazy var player = Player.shared
    private lazy var dataStorage = DataStorage.shared

    // The playback infrastructure
    private let renderer = AVSampleBufferAudioRenderer()
    private let synchronizer = AVSampleBufferRenderSynchronizer()

    static let offsetDidChange = Notification.Name("IKSerializerOffsetDidChange")
    static let itemDidChange = Notification.Name("IKSerializerItemDidChange")
    static let rateDidChange = Notification.Name("IKSerializerRateDidChange")
    static let percentageKey = "IKCurrentPercentage"
    static let currentTimeKey = "IKCurrentTime"
    static let isPlayingKey = "IKIsPlaying"

    private var items: [Item] = []
    var currentItem: Item? { items.first }

    private var nowEnqueuing = 0

    // `enqueuingPlaybackEndTime + enqueuingPlaybackEndOffset` is the time of all playback enqueued so far
    private var enqueuingPlaybackEndTime = CMTime.zero
    private var enqueuingPlaybackEndOffset = CMTime.zero

    // observers
    private var automaticFlushObserver: NSObjectProtocol!
    private var periodicObserver: Any?

    init() {
        synchronizer.addRenderer(renderer)
        automaticFlushObserver = NotificationCenter.default.addObserver(forName: .AVSampleBufferAudioRendererWasFlushedAutomatically,
                                                                        object: renderer,
                                                                        queue: nil) { notification in
            serializationQueue.async {
                let restartTime = (notification.userInfo?[AVSampleBufferAudioRendererFlushTimeKey] as? NSValue)?.timeValue
                self.autoflushPlayback(restartingAt: restartTime)
            }
        }
    }

    func getVolume() -> Float {
        return renderer.volume
    }

    func setVolume(_ vol: Float) {
        if vol > 1 || vol < 0 { return }
        renderer.volume = vol
    }

    func startPlayback() {
        serializationQueue.async { [unowned self] in
            logger.debug("Start playing")
            synchronizer.rate = 1
            notifyRateDidChange()
            updateCurrentPlayingItem(at: .zero)
        }
    }

    func stopPlayback() {
        serializationQueue.async { [unowned self] in
            logger.debug("Stopping playing")
            stopEnqueuing()
            notifyRateDidChange()
        }
    }

    func pausePlayback() {
        serializationQueue.async { [unowned self] in
            logger.debug("Pause playing")
            if synchronizer.rate == 0 { return }
            synchronizer.rate = 0
            notifyRateDidChange()
        }
    }

    func resumePlayback() {
        serializationQueue.async { [unowned self] in
            logger.debug("Resume playing")
            if synchronizer.rate != 0 || items.isEmpty { return }
            synchronizer.rate = 1
            notifyRateDidChange()
        }
    }

    func restartPlayback(with newItems: [Item], atOffset offset: CMTime, atRate rate: Float = 1) {
        serializationQueue.async { [unowned self] in
            stopEnqueuing()

            items = newItems
            items.forEach { $0.startOffset = .zero }

            guard let firstItem = items.first else { return }
            firstItem.startOffset = offset

            nowEnqueuing = 0
            enqueuingPlaybackEndTime = .zero
            enqueuingPlaybackEndOffset = .zero

            updateCurrentPlayingItem(at: .zero)

            provideMediaData(for: CMTime(seconds: 0.25, preferredTimescale: CMTimePreferredTimescale))
            renderer.requestMediaDataWhenReady(on: serializationQueue) {
                self.provideMediaData()
            }

            synchronizer.setRate(rate, time: firstItem.startOffset)
            notifyRateDidChange()
            DispatchQueue.main.async {
                self.player.blockPercentageUpdate = false
            }
        }
    }

    func continuePlayback(with specifiedItems: [Item]) {
        serializationQueue.async { [unowned self] in
            var initialItemCount = 0
            var initialTime = CMTime.zero

            for index in 0 ..< min(items.count, specifiedItems.count) {
                guard items[index] == specifiedItems[index], items[index].isEnqueued else { break }
                initialItemCount += 1
                initialTime += items[index].endOffset
            }

            if initialItemCount == 0 {
                restartPlayback(with: specifiedItems, atOffset: .zero)
                return
            }

            renderer.stopRequestingMediaData()
            renderer.flush(fromSourceTime: initialTime) { succeeded in
                serializationQueue.async {
                    self.finishContinuePlayback(with: specifiedItems, didFlush: succeeded)
                }
            }
        }
    }

    private func finishContinuePlayback(with newItems: [Item], didFlush: Bool) {
        if !didFlush {
            self.restartPlayback(with: newItems, atOffset: .zero)
            return
        }

        var initialItemCount = 0
        var initialEndTime = CMTime.zero

        for index in 0 ..< min(items.count, newItems.count) {
            guard items[index] == newItems[index], items[index].isEnqueued else { break }
            initialItemCount += 1
            initialEndTime += items[index].endOffset
        }

        if initialItemCount == 0 {
            restartPlayback(with: newItems, atOffset: .zero)
            return
        }

        for item in items[initialItemCount...] {
            flushItem(item)
        }

        items = Array(items[0 ..< initialItemCount] + newItems[initialItemCount...])

        if nowEnqueuing > initialItemCount {
            nowEnqueuing = initialItemCount
            enqueuingPlaybackEndTime = initialEndTime
        }

        provideMediaData(for: CMTime(seconds: 0.25, preferredTimescale: CMTimePreferredTimescale))
        renderer.requestMediaDataWhenReady(on: serializationQueue) {
            self.provideMediaData()
        }
    }

    /// - Tag: Private helper functions

    private func notifyRateDidChange() {
        NotificationCenter.default.post(name: Serializer.rateDidChange, object: self, userInfo: [Serializer.isPlayingKey: synchronizer.rate != 0])
    }

    private func stopEnqueuing() {
        synchronizer.rate = 0
        renderer.stopRequestingMediaData()
        renderer.flush()

        for item in items {
            flushItem(item)
        }

        if let observer = periodicObserver {
            logger.debug("Periodic Observer gets removed")
            synchronizer.removeTimeObserver(observer)
            periodicObserver = nil
        }
    }

    private func updateCurrentPlayingItem(at boundaryTime: CMTime) {
        if let observer = periodicObserver {
            synchronizer.removeTimeObserver(observer)
            periodicObserver = nil
        }

        if nowEnqueuing > 0 {
            let item = items.removeFirst()
            flushItem(item)
            nowEnqueuing -= 1
            logger.debug("Flushing the first item")
        }

        NotificationCenter.default.post(name: Serializer.itemDidChange, object: self)

        if items.first != nil {
            let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimePreferredTimescale)
            periodicObserver = synchronizer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [unowned self] _ in
                if let currentSong = dataStorage.selectedPlaylist?.currentSong {
                    let currentTime = CMTimeGetSeconds(synchronizer.currentTime() - boundaryTime)
                    let duration = CMTimeGetSeconds(currentSong.duration)
                    let userInfo = [
                        Serializer.percentageKey: currentTime / duration,
                        Serializer.currentTimeKey: currentTime,
                    ]
                    NotificationCenter.default.post(name: Serializer.offsetDidChange, object: self, userInfo: userInfo)
                }
            }
        } else {
            synchronizer.rate = 0
            notifyRateDidChange()
        }
    }

    private func provideMediaData(for limitedTime: CMTime? = nil) {
        guard nowEnqueuing < items.count else {
            renderer.stopRequestingMediaData()
            return
        }

        var currentItem = items[nowEnqueuing]
        var remainingTime = limitedTime

//        if let seconds = remainingTime?.seconds {
//            logger.debug("Providing \(seconds)s of data for item #\(self.nowEnqueuing)")
//        } else {
//            logger.debug("Providing data for item #\(self.nowEnqueuing)")
//        }

        while renderer.isReadyForMoreMediaData {
            // Stop providing data if provided data exceeded limitTime
            guard remainingTime != .invalid else { break }

            if let buffer = currentItem.nextSample() {
                let pts = CMSampleBufferGetOutputPresentationTimeStamp(buffer)
                if let time = remainingTime {
                    let duration = CMSampleBufferGetDuration(buffer)
                    remainingTime = duration >= time ? .invalid : time - duration
                }
                CMSampleBufferSetOutputPresentationTimeStamp(buffer, newValue: enqueuingPlaybackEndTime + pts)

                enqueuingPlaybackEndOffset = currentItem.endOffset
                renderer.enqueue(buffer)
            } else {
                // play the next item
                // TODO: invalide the current item
                logger.debug("The previous one finished, now providing for the next item")

                nowEnqueuing += 1
                enqueuingPlaybackEndTime += currentItem.endOffset

                let times = [NSValue(time: enqueuingPlaybackEndTime)]
                currentItem.boundaryTimeObserver = synchronizer.addBoundaryTimeObserver(forTimes: times, queue: serializationQueue) {
                    self.updateCurrentPlayingItem(at: self.enqueuingPlaybackEndTime)
                }

                // run out of tracks
                if nowEnqueuing >= items.count {
                    renderer.stopRequestingMediaData()
                    dataStorage.selectedPlaylist?.currentIndex = nil
                    break
                }

                currentItem = items[nowEnqueuing]
            }
        }
    }

    private func autoflushPlayback(restartingAt time: CMTime?) {
        let restartTime = time ?? synchronizer.currentTime()
        logger.debug("automatic flush from \(restartTime)")

        while nowEnqueuing > 0, restartTime < enqueuingPlaybackEndTime {
            let item = items[nowEnqueuing - 1]
            let duration = item.endOffset - item.startOffset

            nowEnqueuing -= 1
            enqueuingPlaybackEndTime -= duration
        }

        let newItems: [Item]
        let offset: CMTime

        if (0 ..< items.count).contains(nowEnqueuing) {
            newItems = Array(items[nowEnqueuing...])
            let firstItem = newItems.first!
            offset = max(min(restartTime - enqueuingPlaybackEndTime, firstItem.endOffset), firstItem.startOffset)
            logger.debug("restarting playback at offset \(offset)")
        } else {
            newItems = []
            offset = .zero
            logger.debug("stopping playback")
        }

        // Restart playback with the new item queue.
        restartPlayback(with: newItems, atOffset: offset, atRate: synchronizer.rate)
    }

    func flushItem(_ item: Item) {
        if let observer = item.boundaryTimeObserver {
            synchronizer.removeTimeObserver(observer)
        }
        item.flush()
    }

}
