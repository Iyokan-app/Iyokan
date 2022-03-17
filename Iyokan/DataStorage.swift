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
                for playlist in self.playlists {
                    if playlist.id == id {
                        self.selectedPlaylist = playlist
                        break
                    }
                }
            }
        }

    }
}
