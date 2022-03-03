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
        let helper = Helper(path)!
        let metadata = helper.getMetadata()

        self.duration = helper.duration
        self.formatName = String(cString: helper.formatName)
        self.sampleRate = helper.sampleRate
        self.bitDepth = helper.bitDepth

        self.title = metadata["title"] ?? "Unknown"
        self.trackNo = Int(metadata["track"] ?? "0") ?? 0
        self.artist = metadata["artist"] ?? "Unknown Artist"
        self.album = metadata["album"] ?? "Unknown Ablum"
    }

    // file data
    let path: String
    let duration: CMTime
    let formatName: String
    let sampleRate: Int32
    let bitDepth: Int32

    // media metadata
    let title: String
    let trackNo: Int
    let artist: String
    let album: String
}
