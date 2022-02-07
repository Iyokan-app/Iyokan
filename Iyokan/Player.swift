//
//  Player.swift
//  Iyokan
//
//  Created by uiryuu on 3/2/2022.
//

import Foundation
import SwiftUI
import os

fileprivate let logger = Logger.init(subsystem: "Iyokan", category: "Player")
fileprivate let lock = DispatchSemaphore(value: 1)

class Player: ObservableObject {
    @Published var percentage: Double = 0.0
    @Published var song: Song?

    private var dataStorage = DataStorage.shared

    let serializer = Serializer()
    private var percentageObserver: NSObjectProtocol!
    private var itemObserver: NSObjectProtocol!

    init() {
        let notificationCenter = NotificationCenter.default
        percentageObserver = notificationCenter.addObserver(forName: Serializer.offsetDidChange, object: serializer, queue: .main) { notification in
            guard let percentage = notification.userInfo?[Serializer.percentageKey] as? Double else { return }
            self.percentage = percentage
        }
        itemObserver = notificationCenter.addObserver(forName: Serializer.itemDidChange, object: serializer, queue: .main) { _ in
            guard let id = self.serializer.currentItem?.id else { return }
            self.dataStorage.selectedPlaylist?.setCurrnetIndex(id: id)
            self.song = self.serializer.currentItem?.song
        }
    }

    func pause() {
        logger.debug("Pausing")
        lock.wait()
        defer { lock.signal() }

        if serializer.isPlaying {
            serializer.pausePlayback()
        }
    }

    func play() {
        logger.debug("Playing")
        lock.wait()
        defer { lock.signal() }

        guard let playlist = dataStorage.selectedPlaylist else { return }

        if playlist.currentIndex == nil {
            restartWithItems(fromIndex: 0, atOffset: .zero)
        } else if !serializer.isPlaying {
            serializer.resumePlayback()
        }
    }

    func seekToOffset(_ offset: CMTime) {
        logger.debug("Seeking to offset \(offset)")
        lock.wait()
        defer { lock.signal() }

        restartWithItems(fromIndex: 0, atOffset: offset)
    }

    private func restartWithItems(fromIndex index: Int, atOffset offset: CMTime) {
        guard let playlist = dataStorage.selectedPlaylist else { return }
        logger.debug("Restarting with total of \(playlist.items.count) items, start at \(index)")
        let items = Array(playlist.items[index ..< playlist.items.count])
        serializer.restartPlayback(with: items, atOffset: offset)
    }
}
