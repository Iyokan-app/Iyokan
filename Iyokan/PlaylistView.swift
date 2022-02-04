//
//  PlaylistView.swift
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

import Foundation
import SwiftUI
import AVFoundation

struct PlaylistView: View {
    @EnvironmentObject var dataStorage: DataStorage
    @ObservedObject var player = Player()

    @State private var selectedItems = Set<Item.ID>()
    @State private var sortOrder = [KeyPathComparator(\Item.song.trackNo)]
    @State private var position: Double = 0

    func timeOffsetChanged(newTime: CMTime) {
        if let currentItem = player.serializer.currentItem {
            position = newTime.seconds / currentItem.song.duration.seconds
        }
    }

    var body: some View {
        VStack {
            Table(dataStorage.selectedPlaylist!.items, selection: $selectedItems, sortOrder: $sortOrder) {
                TableColumn("#", value: \.song.trackNo) {
                    Text(String($0.song.trackNo))
                }.width(min: 10, ideal: 10, max: 50)
                TableColumn("Title", value: \.song.title)
                TableColumn("Artrist", value: \.song.artist)
            }
            .onChange(of: sortOrder) {
                dataStorage.selectedPlaylist!.items.sort(using: $0)
            }
        }
    }
}
