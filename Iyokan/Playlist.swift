//
//  Playlist.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/06.
//

import Foundation

class Playlist: Identifiable, ObservableObject, Hashable {
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }

    init(name: String, items: [Item]?) {
        self.name = name
        self.items = items ?? []
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func addMedia(urls: [URL]) {
        urls.forEach{
            let song = Song($0.path)
            song.decoder.decode()
            items.append(Item(song: song, fromOffset: .zero))
        }
        objectWillChange.send()
    }

    let id = UUID()
    var name: String = ""
    var items: [Item] = []
}
