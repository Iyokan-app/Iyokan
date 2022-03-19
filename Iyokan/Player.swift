//
//  Player.swift
//  Iyokan
//
//  Created by uiryuu on 3/2/2022.
//

import SwiftUI
import MediaPlayer

import os

fileprivate let logger = Logger.init(subsystem: "Iyokan", category: "Player")
fileprivate let lock = DispatchSemaphore(value: 1)

fileprivate let infoCenter = MPNowPlayingInfoCenter.default()

class Player: ObservableObject {
    static let shared = Player()

    private lazy var serializer = Serializer.shared
    private lazy var dataStorage = DataStorage.shared

    // reported by the serializer
    @Published var song: Song?
    @Published var isPlaying: Bool = false
    @Published var percentage: Double = 0.0
    @AppStorage(AppStorageKeys.volume) var volume: Double = 1.0 {
        didSet {
            serializer.setVolume(Float(volume))
        }
    }

    var currentTime: Double = 0
    var currentTimeString: String {
        get {
            String(format: "%02d:%02d", Int(currentTime) / 60, Int(currentTime) % 60)
        }
    }
    var duration: Double = 0
    var durationString: String {
        get {
            String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60)
        }
    }

    private var itemObserver: NSObjectProtocol!
    private var percentageObserver: NSObjectProtocol!
    private var isPlayingObserver: NSObjectProtocol!

    var blockPercentageUpdate = false

    private init() {
        volume = volume // to trigger the didSet closure of volume

        let notificationCenter = NotificationCenter.default

        percentageObserver = notificationCenter.addObserver(forName: Serializer.offsetDidChange, object: serializer, queue: .main) { [unowned self] notification in
            guard !blockPercentageUpdate else { return }
            guard let percentage = notification.userInfo?[Serializer.percentageKey] as? Double else { return }
            self.percentage = percentage

            guard let currentTime = notification.userInfo?[Serializer.currentTimeKey] as? Double else { return }
            self.currentTime = currentTime
            guard var info = infoCenter.nowPlayingInfo else { return }
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            infoCenter.nowPlayingInfo = info
        }

        itemObserver = notificationCenter.addObserver(forName: Serializer.itemDidChange, object: serializer, queue: .main) { [unowned self] _ in
            guard let id = serializer.currentItem?.id else { return }
            dataStorage.selectedPlaylist?.setCurrnetIndex(id: id)
            song = serializer.currentItem?.song

            guard let song = song else { infoCenter.nowPlayingInfo = nil; return }
            duration = CMTimeGetSeconds(song.duration)

            let info: [String: Any] = [
                MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
                MPMediaItemPropertyArtist: song.artist,
                MPMediaItemPropertyTitle: song.title,
                MPMediaItemPropertyPlaybackDuration: duration,
            ]
            infoCenter.playbackState = .playing
            infoCenter.nowPlayingInfo = info
        }

        isPlayingObserver = notificationCenter.addObserver(forName: Serializer.rateDidChange, object: serializer, queue: .main) { [unowned self] notification in
            guard let isPlaying = notification.userInfo?[Serializer.isPlayingKey] as? Bool else { return }
            self.isPlaying = isPlaying

            infoCenter.playbackState = isPlaying ? .playing : .paused
            guard var info = infoCenter.nowPlayingInfo else { return }
            guard song != nil else { return }
            info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1 : 0
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            infoCenter.nowPlayingInfo = info
        }
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func pause() {
        logger.debug("Pausing")
        lock.wait()
        defer { lock.signal() }

        if isPlaying {
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
        } else if !isPlaying {
            serializer.resumePlayback()
        }
    }

    func previous() {
        lock.wait()
        defer { lock.signal() }

        guard let playlist = dataStorage.selectedPlaylist else { return }
        guard let index = playlist.currentIndex else { return }
        restartWithItems(fromIndex: index, atOffset: .zero)
    }

    func next() {
        lock.wait()
        defer { lock.signal() }

        guard let playlist = dataStorage.selectedPlaylist else { return }
        guard let index = playlist.currentIndex else { return }
        if index == playlist.items.count - 1 { return }
        restartWithItems(fromIndex: index + 1, atOffset: .zero)
    }

    func seekToOffset(_ offset: CMTime) {
        logger.debug("Seeking to offset \(offset)")
        lock.wait()
        defer { lock.signal() }

        guard let currentIndex = dataStorage.selectedPlaylist?.currentIndex else { return }
        restartWithItems(fromIndex: currentIndex, atOffset: offset, pause: !isPlaying)
    }

    func seekToItem(_ item: Item) {
        logger.debug("Seeking to item \(item.song.title)")
        guard let playlist = dataStorage.selectedPlaylist else { return }
        lock.wait()
        defer { lock.signal() }

        guard let index = playlist.items.firstIndex(of: item) else { return }
        restartWithItems(fromIndex: index, atOffset: .zero)
    }

    // called when the playlist has been changed
    func continueWithCurrentItems() {
        logger.debug("Coninue with current items")
        guard let playlist = dataStorage.selectedPlaylist,
              let currentIndex = playlist.currentIndex else { return }
        lock.wait()
        defer { lock.signal() }
        let items = Array(playlist.items[currentIndex ..< playlist.items.count])

        serializer.continuePlayback(with: items)
    }

    private func restartWithItems(fromIndex index: Int, atOffset offset: CMTime, pause: Bool = false) {
        guard let playlist = dataStorage.selectedPlaylist else { return }
        logger.debug("Restarting with total of \(playlist.items.count) items, start at \(index)")
        let items = Array(playlist.items[index ..< playlist.items.count])
        serializer.restartPlayback(with: items, atOffset: offset, atRate: pause ? 0 : 1)
    }
}
