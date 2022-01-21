//
//  DataStorage.swift
//  Dimko
//
//  Created by uiryuu on 2021/07/06.
//

import Foundation

class DataStorage: ObservableObject {
    var playlists: [Playlist] = []
    @Published var selectedPlaylist: Playlist?

    func append(_ item: Playlist) {
        playlists.append(item)
        selectedPlaylist = item
        objectWillChange.send();
    }

    func remove(_ item: Playlist?) {
        guard let target = item ?? selectedPlaylist else { return }
        guard let index = playlists.firstIndex(of: target) else { return }
        playlists.remove(at: index)
        selectedPlaylist = nil
        if (item == nil) && !playlists.isEmpty {
            selectedPlaylist = playlists[0]
        }
        objectWillChange.send();
    }
}
