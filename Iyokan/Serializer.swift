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

class Serializer: ObservableObject {
    // The playback infrastructure
    private let renderer = AVSampleBufferAudioRenderer()
    private let synchronizer = AVSampleBufferRenderSynchronizer()

    var items: [Item] = []

    var currentItem: Item? {
        return items.first
    }

    private var nowEnqueuing = 0

    // `enqueuingPlaybackEndTime + enqueuingPlaybackEndOffset` is the time of all playback enqueued so far
    private var enqueuingPlaybackEndTime = CMTime.zero
    private var enqueuingPlaybackEndOffset = CMTime.zero

    // observers
    private var automaticFlushObserver: NSObjectProtocol!
    private var periodicObserver: Any?

    // logger
    private let logger = Logger(subsystem: "Serializer", category: "Playback")

    var isPlaying: Bool { synchronizer.rate != 0 }

    @Published var percentage: Double = 0.0

    init() {
        synchronizer.addRenderer(renderer)
        automaticFlushObserver = NotificationCenter.default.addObserver(forName: .AVSampleBufferAudioRendererWasFlushedAutomatically,
                                                                        object: renderer,
                                                                        queue: nil) { [unowned self] notification in
            serializationQueue.async {
                let restartTime = (notification.userInfo?[AVSampleBufferAudioRendererFlushTimeKey] as? NSValue)?.timeValue
                self.autoflushPlayback(restartingAt: restartTime)
            }
        }
    }

    func startPlayback() {
        serializationQueue.async {
            self.synchronizer.rate = 1
            self.updateCurrentPlayingItem(at: .zero)
        }
    }

    func stopPlayback() {
        serializationQueue.async {
            print("Stopping playing")
            self.stopEnqueuing()
        }
    }

    func pausePlayback() {
        serializationQueue.async {
            print("pausing playback")
            if self.synchronizer.rate == 0 { return }
            self.synchronizer.rate = 0
        }
    }

    func resumePlayback() {
        serializationQueue.async {
            if self.synchronizer.rate != 0 || self.items.isEmpty { return }
            self.synchronizer.rate = 0
        }
    }

    func restartPlayback(with newItems: [Item], atOffset offset: CMTime) {
        serializationQueue.async {
            self.stopEnqueuing()

            self.items = newItems
            self.items.forEach { $0.startOffset = .zero }

            guard let firstItem = self.items.first else { return }
            firstItem.startOffset = offset

            self.nowEnqueuing = 0
            self.enqueuingPlaybackEndTime = .zero
            self.enqueuingPlaybackEndOffset = .zero

            self.updateCurrentPlayingItem(at: .zero)

            self.provideMediaData(for: CMTime(seconds: 0.25, preferredTimescale: 1000))
            self.renderer.requestMediaDataWhenReady(on: serializationQueue) { [unowned self] in
                self.provideMediaData()
            }

            self.synchronizer.setRate(1, time: firstItem.startOffset)
        }
    }

    func continuePlayback(with specifiedItems: [Item]) {
        serializationQueue.async {
            self._continuePlayback(with: specifiedItems)
        }
    }

    private func _continuePlayback(with newItems: [Item]) {
        var initialItemCount = 0
        var initialTime = CMTime.zero

        for index in 0 ..< min(items.count, newItems.count) {
            guard items[index] == newItems[index], items[index].isEnqueued else { break }
            initialItemCount += 1
            initialTime = initialTime + items[index].endOffset
        }

        if initialItemCount == 0 {
            restartPlayback(with: newItems, atOffset: .zero)
            return
        }

        renderer.stopRequestingMediaData()
        renderer.flush(fromSourceTime: initialTime) { succeeded in
            serializationQueue.async {
                self.finishContinuePlayback(with: newItems, didFlush: succeeded)
            }
        }
    }

    private func finishContinuePlayback(with newItems: [Item], didFlush: Bool) {
        guard didFlush else { self.restartPlayback(with: newItems, atOffset: .zero); return }

        var initialItemCount = 0
        var initialEndTime = CMTime.zero

        for index in 0 ..< min(items.count, newItems.count) {
            guard items[index] == newItems[index], items[index].isEnqueued else { break }
            initialItemCount += 1
            initialEndTime = initialEndTime + items[index].endOffset
        }

        if initialItemCount == 0 {
            restartPlayback(with: newItems, atOffset: .zero)
            return
        }

        // TODO: flush unwanted items

        items = Array(items[0 ..< initialItemCount] + newItems[initialItemCount...])

        if nowEnqueuing > initialItemCount {
            nowEnqueuing = initialItemCount
            enqueuingPlaybackEndTime = initialEndTime
        }

        provideMediaData(for: CMTime(seconds: 0.25, preferredTimescale: 1000))
        renderer.requestMediaDataWhenReady(on: serializationQueue) { [unowned self] in
            self.provideMediaData()
        }
    }

    /// - Tag: Private functions

    private func stopEnqueuing() {
        synchronizer.rate = 0
        renderer.stopRequestingMediaData()
        renderer.flush()
    }

    private func updateCurrentPlayingItem(at boundaryTime: CMTime) {
        if let observer = periodicObserver {
            synchronizer.removeTimeObserver(observer)
            periodicObserver = nil
        }

        if items.first != nil {
            let interval = CMTime(seconds: 0.1, preferredTimescale: 1000)
            periodicObserver = synchronizer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [unowned self] _ in
                if let currentSong = currentItem?.song {
                    let currentTime = CMTimeGetSeconds(synchronizer.currentTime())
                    let duration = CMTimeGetSeconds(currentSong.duration)
                    percentage = currentTime / duration
                }
            }
        } else {
            synchronizer.rate = 0
        }
    }

    private func provideMediaData(for limitedTime: CMTime? = nil) {
        guard nowEnqueuing < items.count else {
            renderer.stopRequestingMediaData()
            return
        }

        var currentItem = items[nowEnqueuing]
        var remainingTime = limitedTime

        if let seconds = remainingTime?.seconds {
            print("Providing \(seconds)s of data for item $\(nowEnqueuing)")
        } else {
            print("Providing data for item $\(nowEnqueuing)")
        }

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

                enqueuingPlaybackEndTime = currentItem.endOffset
                renderer.enqueue(buffer)
            } else {
                // play the next item
                // TODO: invalide the current item

                nowEnqueuing += 1
                enqueuingPlaybackEndTime = enqueuingPlaybackEndTime + currentItem.endOffset

                let times = [NSValue(time: enqueuingPlaybackEndTime)]
                currentItem.boundaryTimeObserver = synchronizer.addBoundaryTimeObserver(forTimes: times, queue: serializationQueue) { [unowned self] in
                    self.updateCurrentPlayingItem(at: enqueuingPlaybackEndTime)
                }

                // run out of tracks
                if nowEnqueuing >= items.count {
                    renderer.stopRequestingMediaData()
                    break
                }

                currentItem = items[nowEnqueuing]
            }
        }
    }

    private func autoflushPlayback(restartingAt time: CMTime?) {
        let restartTime = time ?? synchronizer.currentTime()
        print("automatic flush from \(restartTime)")

        while nowEnqueuing > 0, restartTime < enqueuingPlaybackEndTime {
            let item = items[nowEnqueuing - 1]
            let duration = item.endOffset - item.startOffset

            nowEnqueuing -= 1
            enqueuingPlaybackEndTime = enqueuingPlaybackEndTime - duration
        }

        let newItems: [Item]
        let offset: CMTime

        if (0 ..< items.count).contains(nowEnqueuing) {
            newItems = Array(items[nowEnqueuing...])
            let firstItem = newItems.first!
            offset = max(min(restartTime - enqueuingPlaybackEndTime, firstItem.endOffset), firstItem.startOffset)
            print("restarting playback at offset \(offset)")
        } else {
            newItems = []
            offset = .zero
            print("stopping playback")
        }

        // Restart playback with the new item  queue.
        restartPlayback(with: newItems, atOffset: offset)
    }

}
