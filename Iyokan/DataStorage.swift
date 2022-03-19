//
//  DataStorage.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/06.
//

import Foundation
import SwiftUI

class DataStorage: ObservableObject {
    static let shared = DataStorage()

    let tempPlaylist: Playlist
    @Published var playlists: [Playlist] = []
    @Published var localPlaylists: [LocalPlaylist] = []

    @Published var selectedPlaylist: Playlist?

    var allPlaylists: [Playlist] {
        playlists + localPlaylists + [tempPlaylist]
    }

    init() {
        tempPlaylist = Playlist(name: String(localized: "Temporary Playlist"), items: nil)
        selectedPlaylist = tempPlaylist
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

        playlists.removeAll(where: { $0 == target })
        localPlaylists.removeAll(where: { $0 == target })

        if target == selectedPlaylist {
            selectedPlaylist = tempPlaylist
        }
    }

    func movePlaylists(from source: IndexSet, to destination: Int) {
        playlists.move(fromOffsets: source, toOffset: destination)
    }

    // https://stackoverflow.com/a/66129676
    func selectionBindingForId(id: UUID) -> Binding<Bool> {
        Binding<Bool> { () -> Bool in
            guard let selectedID = self.selectedPlaylist?.id else { return false }
            return id == selectedID
        } set: { newValue in
            if newValue {
                for playlist in self.allPlaylists {
                    if playlist.id == id {
                        self.selectedPlaylist = playlist
                        break
                    }
                }
            }
        }

    }
}
