//
//  DataStorage.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/06.
//

import Foundation
import SwiftUI

class DataStorage: ObservableObject, Codable {
    static let shared: DataStorage = {
        do {
            if let data = try? Data(contentsOf: storageURL) {
                let decoder = PropertyListDecoder()
                if let dataStorage = try? decoder.decode(DataStorage.self, from: data) {
                    return dataStorage
                }
            }
        }
        return DataStorage()
    }()

    let tempPlaylist = Playlist(name: String(localized: "Temporary Playlist"), items: nil)
    @Published var playlists: [Playlist]
    @Published var localPlaylists: [LocalPlaylist]

    @Published var selectedPlaylist: Playlist?

    var allPlaylists: [Playlist] {
        playlists + localPlaylists + [tempPlaylist]
    }

    init() {
        playlists = []
        localPlaylists = []
        selectedPlaylist = tempPlaylist
    }

    enum CodingKeys: String, CodingKey {
        case playlists, localPlaylists
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playlists = try container.decode(Array<Playlist>.self, forKey: .playlists)
        // localPlaylists = try container.decode(Array<LoaclPlaylist>.self, forKey: .localPlaylists)
        localPlaylists = []
        selectedPlaylist = tempPlaylist
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playlists, forKey: .playlists)
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
