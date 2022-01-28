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
        self.trackNo = (metadata["track"]! as NSString).integerValue
        self.artist = metadata["artist"] ?? "Unkown Artist"

        // FIXME
        self.duration = CMTime.init(value: 10000, timescale: 100)
    }
    let path: String
    let decoder: Decoder

    // metadata
    let title: String
    let trackNo: Int
    let artist: String

    let duration: CMTime
}
