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

    @State private var hovering: [Item] = []

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
            GeometryReader { geometry in
                Table(dataStorage.selectedPlaylist!.items, selection: $selectedItems, sortOrder: $sortOrder) {
                    TableColumn("#", value: \.song.trackNo) { row in
                        Text(String(row.song.trackNo))
                            // Extend the length of the text view to detect the cursor
                            // 24 is the default height of a NSTableView row
                            .frame(width: geometry.size.width, height: 24, alignment: .leading)
                            .onHover() { inside in
                                lastHovering = inside
                                if inside {
                                    if self.hovering.count > 2 {
                                        _ = self.hovering.dropFirst()
                                    }
                                    self.hovering.append(row)
                                } else {
                                    self.hovering.removeAll(where: { $0 == row })
                                }
                            }
                            .contextMenu {
                                Button("test") {

                                }
                            }
                    }
                    .width(20)
                    TableColumn("Title", value: \.song.title)
                    TableColumn("Artist", value: \.song.artist)
                }
                .contextMenu {
                    Button("Add Files") {
                        openFile()
                    }
                    if $hovering.count != 0 {
                        Button(hovering.last!.song.title) {}
                    }
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
}
