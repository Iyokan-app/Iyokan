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

    // logger
    private let logger = Logger(subsystem: "Serializer", category: "Playback")

    var isPlaying: Bool { synchronizer.rate != 0 }

    // published states
    @Published var playerState: Bool = false

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
}
