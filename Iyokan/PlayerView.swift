//
//  PlayerView.swift
//  Iyokan
//
//  Created by uiryuu on 3/2/2022.
//

import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var dataStorage: DataStorage
    @ObservedObject var player = Player()

    func togglePlay() {
        guard let playlist = dataStorage.selectedPlaylist else { return }
        guard !playlist.items.isEmpty else { return }
        if player.serializer.isPlaying {
            player.serializer.stopPlayback()
        } else {
            // serializer.items = playlist.items
            // serializer.startPlayback()
            player.serializer.restartPlayback(with: playlist.items, atOffset: .zero)
        }
    }

    func previous() {
        print("previous")
    }

    func next() {
        print("next")
    }

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
        Slider(value: $player.percentage, in: 0...1, onEditingChanged: {_ in })
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

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}
