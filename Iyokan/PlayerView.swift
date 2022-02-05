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
                        player.play()
                    }
                }
                HStack(alignment: .center, spacing: 20) {
                    Button(action: previous) {
                        Image(systemName: "backward.fill")
                    }.buttonStyle(.borderless)
                    Button(action: togglePlay) {
                        Image(systemName: "playpause.fill")
                    }.buttonStyle(.borderless)
                    Button(action: next) {
                        Image(systemName: "forward.fill")
                    }.buttonStyle(.borderless)
                    Spacer()
                }.padding(.bottom)
            }.padding(.horizontal, nil)
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}
