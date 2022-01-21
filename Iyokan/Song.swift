//
//  Song.swift
//  Dimko
//
//  Created by uiryuu on 2021/07/06.
//

import Foundation

struct Song: Identifiable, Hashable {
    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(_ path: String) {
        self.path = path
        self.decoder = Decoder(path)

        let metadata = decoder.getMetadata()
        self.title = metadata["title"] ?? "Unkown"
        self.trackNo = (metadata["track"]! as NSString).integerValue
        self.artist = metadata["artist"] ?? "Unkown Artist"
    }
    let id = UUID()
    let path: String
    let decoder: Decoder

    // metadata
    let title: String
    let trackNo: Int
    let artist: String
}
