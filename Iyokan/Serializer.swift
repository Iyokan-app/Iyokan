//
//  Serializer.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/06.
//

import Foundation
import AVFoundation
import os

class Serializer: ObservableObject {
    private let serializationQueue = DispatchQueue(label: "org.iyokan-app.iyokan.serialization.queue", qos: .userInteractive)

    // The playback infrastructure
    private let renderer = AVSampleBufferAudioRenderer()
    private let synchronizer = AVSampleBufferRenderSynchronizer()

    private var items: [Song] = []

    var currentItem: Song? {
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

    // published states
    @Published var playerState: Bool = false

    init() {
        synchronizer.addRenderer(renderer)

        automaticFlushObserver = NotificationCenter.default.addObserver(forName: .AVSampleBufferAudioRendererWasFlushedAutomatically,
                                                                        object: renderer,
                                                                        queue: nil) { [unowned self] notification in
            self.serializationQueue.async {
                let restartTime = (notification.userInfo?[AVSampleBufferAudioRendererFlushTimeKey] as? NSValue)?.timeValue
                // self.autoflushPlayback(restartAt: restartTime)
            }
        }
    }

    func stopPlayback() {
        logger.trace("Stopping the serializer")
        serializationQueue.async {
            self.stopEnqueuingItems()
            self.playerState = false
        }
    }

    // only called on serializationQueue
    private func stopEnqueuingItems() {
        // stop playback, if something is playing
        synchronizer.rate = 0
        renderer.stopRequestingMediaData()
        renderer.flush()

        // TODO: flush items
        // TODO: stop periodic notifications
    }

    func restartPlayback(with newItems: [Item], atOffset offset: CMTime) {
        // logger.trace("restarted playback with \(newSongs.count) items, from offset +\(offset.seconds)")

        // logging or something idk
//        var elapsed = CMTime.zero
//        for (index, item) in newSongs.enumerated() {
//            elapsed = elapsed + item.duraton
//            log elapsed
//        }

        stopEnqueuingItems()

        // remove songs with 0 duration, dk why

        guard let firstItem = newItems.first else { return }
        firstItem.startOffset = offset

        // reset enqueuing states
        enqueuingIndex = 0
        enqueuingPlaybackEndTime = .zero
        enqueuingPlaybackEndOffset = .zero
    }
}


// public

// stopQueue: Player action: Stop
    // call stopPlayback in serialization queue

// restartQueue: replace a playlist
    // call restartPlayback in serialization queue

// continueQueue: coninue playing the current item
    // call continuePlayback in serialization queue

// pauseQueue: Player action: Pause
    // call pausePlayback in serialization queue

// resumeQueue: Player action: Resume
    // call resumePlayback in serilization queue

// playbackrate (public getter): get current playing/paused state

// sampleBufferItem: create a new sample buffer item from a item in the list, with offset



// private

// restartPlayback (newItems, offset)


// finishContinuePlayback (newItems, didFlush)
// stopEnqueuingItems

// provideMediaData(limitedTime?)

// updateCurrentPlayerItem(boundaryTime)

// notifyTimeOffsetChanged(from baseTime)
// notifyPlaybackRateChanged(from oldRate)

// autoFlushPlayback(restartingTime?)
// flushItem(item)
