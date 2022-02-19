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
        let decoder = Decoder(path)
        let metadata = decoder.getMetadata()
        self.title = metadata["title"] ?? "Unknown"
        self.trackNo = Int(metadata["track"] ?? "0") ?? 0
        self.artist = metadata["artist"] ?? "Unknown Artist"
        self.album = metadata["album"] ?? "Unknown Ablum"

        self.duration = decoder.getDuration()
        self.formatName = decoder.formatName
        self.sampleRate = decoder.sampleRate
    }
    let path: String

    // metadata
    let title: String
    let trackNo: Int
    let artist: String
    let album: String

    let duration: CMTime
    let formatName: String
    let sampleRate: Int32
}
