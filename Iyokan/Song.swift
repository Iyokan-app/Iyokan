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
        let name = String(cString: helper.codecName)
        if name.starts(with: "pcm") {
            self.codecName = "PCM"
        } else if name.starts(with: "mp3") {
            self.codecName = "MP3"
        } else {
            self.codecName = name
        }
        self.sampleRate = helper.sampleRate
        self.bitDepth = helper.bitDepth

        self.title = metadata["title"] ?? String(localized: "Unknown", comment: "Unknown song title")
        self.trackNo = Int(metadata["track"] ?? "0") ?? 0
        self.artist = metadata["artist"] ?? String(localized: "Unknown Artist")
        self.album = metadata["album"] ?? String(localized: "Unknown Ablum")
    }

    // file data
    let path: String
    let duration: CMTime
    let codecName: String
    let sampleRate: Int32
    let bitDepth: Int32

    // media metadata
    let title: String
    let trackNo: Int
    let artist: String
    let album: String
}
