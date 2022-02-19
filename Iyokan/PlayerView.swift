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
    @State var showingPopover = false

    var body: some View {
        HStack {
            Slider(value: $player.percentage, in: 0...1) { editing in
                if editing {
                    player.blockPercentageUpdate = true
                } else {
                    guard let duration = player.song?.duration else { return }
                    player.seekToOffset(CMTimeMultiplyByFloat64(duration, multiplier: player.percentage))
                }
            }
            .controlSize(.small)
        }
        .padding(.horizontal)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                HStack {
                    Button(action: player.previous) {
                        Image(systemName: "backward.fill")
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    Button(action: player.toggle) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .keyboardShortcut(" ", modifiers: [])
                    Button(action: player.next) {
                        Image(systemName: "forward.fill")
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    if $player.song.wrappedValue != nil {
                        ZStack {
                            Text(player.song!.formatName.uppercased())
                                .bold()
                                .font(.system(size: 12))
                                .foregroundColor(.black)
                                .padding(.horizontal, 3)
                        }
                        .background(.gray)
                        .cornerRadius(2)
                        .onTapGesture {
                            showingPopover = true
                        }
                        .popover(isPresented: $showingPopover) {
                            let str = "Sample Rate: \(player.song!.sampleRate) kHz"
                            Text(str).padding()
                        }
                        VStack(alignment: .leading) {
                                Text($player.song.wrappedValue!.title).bold()
                                Text($player.song.wrappedValue!.artist).foregroundColor(.secondary)
                        }.padding(.vertical)
                    }
                }
            }
            ToolbarItem() {
                Spacer()
            }
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}
