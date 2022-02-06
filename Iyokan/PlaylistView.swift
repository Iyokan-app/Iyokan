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

    @State private var selectedItems = Set<Item.ID>()
    @State private var sortOrder = [KeyPathComparator(\Item.song.trackNo)]
    @State private var position: Double = 0

    func openFile() {
        guard let playlist = dataStorage.selectedPlaylist else { return }
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.audio]
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.beginSheetModal(for: NSApp.keyWindow!) {_ in
            playlist.addMedia(urls: openPanel.urls)
            dataStorage.objectWillChange.send()
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
            .toolbar {
                ToolbarItem() {
                    Spacer()
                }
                ToolbarItem() {
                    Button(action: openFile) {
                        Image(systemName: "doc.badge.plus")
                    }.controlSize(.large)
                }
            }
        }
    }
}
