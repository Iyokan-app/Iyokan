//
//  Song.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/06.
//

import Foundation
import CoreMedia

struct Song {
    init(_ path: String) {
        self.path = path
        self.decoder = Decoder(path)

        let metadata = decoder.getMetadata()
        self.title = metadata["title"] ?? "Unkown"
        self.trackNo = Int(metadata["track"] ?? "0") ?? 0
        self.artist = metadata["artist"] ?? "Unkown Artist"

        self.duration = decoder.getDuration()
    }
    let path: String
    let decoder: Decoder

    // metadata
    let title: String
    let trackNo: Int
    let artist: String

    let duration: CMTime
}
