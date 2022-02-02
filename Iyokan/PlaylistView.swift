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

    @ObservedObject var playlist: Playlist
    @ObservedObject var serializer = Serializer()

    @State private var selectedItems = Set<Item.ID>()
    @State private var sortOrder = [KeyPathComparator(\Item.song.trackNo)]
    @State private var position: Double = 1

    func togglePlay() {
        guard !playlist.items.isEmpty else { return }
        if (serializer.isPlaying) {
            serializer.stopPlayback()
        } else {
            // serializer.items = playlist.items
            // serializer.startPlayback()
            serializer.restartPlayback(with: playlist.items, atOffset: .zero)
        }
    }

    func previous() {
        print("previous")
    }

    func next() {
        print("next")
    }

    func openFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.audio]
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.beginSheetModal(for: NSApp.keyWindow!) {_ in
            playlist.addMedia(urls: openPanel.urls)
        }
    }

    func timeOffsetChanged(newTime: CMTime) {
        if let currentItem = serializer.currentItem {
            position = newTime.seconds / currentItem.song.duration.seconds
        }
    }

    var body: some View {
        VStack {
            Table(playlist.items, selection: $selectedItems, sortOrder: $sortOrder) {
                TableColumn("#", value: \.song.trackNo) {
                    Text(String($0.song.trackNo))
                }.width(min: 10, ideal: 10, max: 50)
                TableColumn("Title", value: \.song.title)
                TableColumn("Artrist", value: \.song.artist)
            }
            .onChange(of: sortOrder) {
                playlist.items.sort(using: $0)
            }
            Slider(value: $serializer.percentage, in: 0...1, onEditingChanged: {_ in })
                .padding(.horizontal, nil)
            HStack {
                Button(action: previous) {
                    Image(systemName: "backward.fill")
                }.buttonStyle(.borderless).padding()
                Button(action: togglePlay) {
                    Image(systemName: "playpause.fill")
                }.buttonStyle(.borderless).padding()
                Button(action: next) {
                    Image(systemName: "forward.fill")
                }.buttonStyle(.borderless).padding()

                Button(action: openFile) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless).padding()
            }
        }
    }
}
