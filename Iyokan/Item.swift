//
//  Item.swift
//  Dimko
//
//  Created by uiryuu on 2021/07/07.
//

import Foundation
import AVFoundation
import os

class Item {
    let song: Song
    var startOffset: CMTime {
        didSet {
            endOffset = startOffset
        }
    }
    private(set) var endOffset: CMTime

    private let logger = Logger.init(subsystem: "Item", category: "Playback")

    init (song: Song, fromOffset offset: CMTime) {
        self.song = song
        self.startOffset = offset
        self.endOffset = offset
    }
}
