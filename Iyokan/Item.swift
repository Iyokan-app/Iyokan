//
//  Item.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/07.
//

import Foundation
import AVFoundation
import os

fileprivate let logger = Logger.init(subsystem: "Iyokan", category: "Item")

class Item: Identifiable, Hashable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id = UUID()
    let song: Song
    private var decoder: Decoder?

    var boundaryTimeObserver: Any?

    var startOffset: CMTime {
        didSet {
            endOffset = startOffset
        }
    }
    private(set) var endOffset: CMTime

    // true if this item has been used to get sample buffers
    private(set) var isEnqueued = false

    init (song: Song, fromOffset offset: CMTime) {
        self.song = song
        self.startOffset = offset
        self.endOffset = offset

        self.startOffset = offset > .zero && offset < song.duration ? offset : .zero
    }

    func nextSample() -> CMSampleBuffer? {
        if decoder == nil {
            isEnqueued = true
            decoder = Decoder(song.path)
        }
        // logger.debug("Making sample for \(self.song.title)")

        guard let buffer = decoder?.nextSampleBuffer() else { return nil }
        endOffset = buffer.presentationTimeStamp + buffer.duration
        return buffer
    }

    func flush() {
        isEnqueued = false
        decoder = nil
        boundaryTimeObserver = nil
    }
}
