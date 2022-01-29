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

    private var enqueuingIndex = 0

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
//        automaticFlushObserver = NotificationCenter.default.addObserver(forName: .AVSampleBufferAudioRendererWasFlushedAutomatically,
//                                                                        object: renderer,
//                                                                        queue: nil) { [unowned self] notification in
//            serializationQueue.async {
//                let restartTime = (notification.userInfo?[AVSampleBufferAudioRendererFlushTimeKey] as? NSValue)?.timeValue
//                // self.autoflushPlayback(restartAt: restartTime)
//            }
//        }
    }

    func startPlayback() {
        renderer.requestMediaDataWhenReady(on: serializationQueue) {
         while self.renderer.isReadyForMoreMediaData {
                if let sampleBuffer = self.currentItem?.song.decoder.nextSampleBuffer() {
                    self.renderer.enqueue(sampleBuffer)
                }
            }
        }
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
}
