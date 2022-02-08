//
//  PlayerView.swift
//  Iyokan
//
//  Created by uiryuu on 3/2/2022.
//

import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var dataStorage: DataStorage

    @ObservedObject var player = Player.shared

    func togglePlay() {
        guard let playlist = dataStorage.selectedPlaylist else { return }
        guard !playlist.items.isEmpty else { return }
        if player.serializer.isPlaying {
            player.serializer.pausePlayback()
        } else {
            player.play()
        }
    }

    func previous() {
        print("previous")
    }

    func next() {
        print("next")
    }

    var body: some View {
        HStack {
            VStack {
                Slider(value: $player.percentage, in: 0...1) { editing in
                    if editing {
                        player.pause()
                    } else {
                        guard let index = dataStorage.selectedPlaylist?.currentIndex else { return }
                        let duration = dataStorage.selectedPlaylist!.items[index].song.duration
                        player.seekToOffset(CMTimeMultiplyByFloat64(duration, multiplier: player.percentage))
                    }
                }.padding(.horizontal)
            }
        }.toolbar {
            ToolbarItemGroup(placement: .navigation) {
                HStack {
                    Button(action: previous) {
                        Image(systemName: "backward.fill")
                    }
                    Button(action: togglePlay) {
                        Image(systemName: "playpause.fill")
                    }
                    Button(action: next) {
                        Image(systemName: "forward.fill")
                    }
                    // Divider()
                    VStack(alignment: .leading) {
                        if $player.song.wrappedValue != nil {
                            Text($player.song.wrappedValue!.title).bold()
                            Text($player.song.wrappedValue!.artist).foregroundColor(.secondary)
                        }
                    }.padding(.vertical)
                }
            }
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}
