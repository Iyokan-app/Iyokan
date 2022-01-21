//
//  PlaylistView.swift
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

import Foundation
import SwiftUI
import AVFoundation

var decoder: Decoder?

struct PlaylistView: View {

    @ObservedObject var playlist: Playlist

    @State private var selectedSongs = Set<Song.ID>()
    @State private var sortOrder = [KeyPathComparator(\Song.trackNo)]
    @State private var position: Double = 1

    func togglePlay() {
        guard !playlist.items.isEmpty else { return }
        let song = playlist.items[0]
        decoder = Decoder(song.path)
        decoder!.decode()
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

    var body: some View {
        VStack {
            Table(playlist.items, selection: $selectedSongs, sortOrder: $sortOrder) {
                TableColumn("#", value: \.trackNo) {
                    Text(String($0.trackNo))
                }.width(min: 10, ideal: 10, max: 50)
                TableColumn("Title", value: \.title)
                TableColumn("Artrist", value: \.artist)
            }
            .onChange(of: sortOrder) {
                playlist.items.sort(using: $0)
            }
            Slider(value: $position, in: 0...100, onEditingChanged: {_ in })
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
