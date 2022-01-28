//
//  Item.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/07.
//

import Foundation
import AVFoundation
import os

class Item: Identifiable, Hashable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id = UUID()
    let song: Song

    var startOffset: CMTime {
        didSet {
            endOffset = startOffset
        }
    }
    private(set) var endOffset: CMTime

    // true if this item has been used to get sample buffers
    private(set) var isEnqueued = false

    private let logger = Logger.init(subsystem: "Item", category: "Playback")
    private var logCount = 0

    init (song: Song, fromOffset offset: CMTime) {
        self.song = song
        self.startOffset = offset
        self.endOffset = offset

        self.startOffset = offset > .zero && offset < song.duration ? offset : .zero
    }
}
