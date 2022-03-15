//
//  DataStorage.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/06.
//

import Foundation

class DataStorage: ObservableObject {
    static let shared = DataStorage()

    @Published var playlists: [Playlist] = []
    @Published var selectedPlaylist: Playlist?

    init() {
        newPlaylist()
    }

    func newPlaylist() {
        append(Playlist(name: String(localized: "Untitled Playlist"), items: nil))
    }

    func append(_ item: Playlist) {
        playlists.append(item)
        selectedPlaylist = item
    }

    func remove(_ item: Playlist?) {
        guard let target = item ?? selectedPlaylist else { return }
        guard let index = playlists.firstIndex(of: target) else { return }
        playlists.remove(at: index)
        selectedPlaylist = nil
        if (item == nil) && !playlists.isEmpty {
            selectedPlaylist = playlists[0]
        }
    }
}
