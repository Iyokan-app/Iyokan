//
//  PlayerView.swift
//  Iyokan
//
//  Created by uiryuu on 3/2/2022.
//

import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var dataStorage: DataStorage
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var player = Player.shared
    @State var showingPopover = false

    var body: some View {
        HStack {
            Slider(value: $player.percentage, in: 0...1) {
            } minimumValueLabel: {
                Text(player.currentTimeString).monospacedDigit().foregroundColor(.gray)
            } maximumValueLabel: {
                Text(player.durationString).monospacedDigit().foregroundColor(.gray)
            } onEditingChanged: { editing in
                if editing {
                    player.blockPercentageUpdate = true
                } else {
                    if let duration = player.song?.duration {
                        player.seekToOffset(CMTimeMultiplyByFloat64(duration, multiplier: player.percentage))
                    }
                }
            }
            .controlSize(.small)
        }
        .padding(.horizontal)
        // this hack might can be removed in a later macOS version
        .background(colorScheme == .light ? Color.init(nsColor: .controlColor) : nil)
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
                            Text(player.song!.codecName.uppercased())
                                .bold()
                                .font(.system(size: 12))
                                .foregroundColor(.init(nsColor: .controlBackgroundColor))
                                .padding(.horizontal, 3)
                                .lineLimit(1)
                        }
                        .background(.gray)
                        .cornerRadius(2)
                        .onTapGesture {
                            showingPopover = true
                        }
                        .popover(isPresented: $showingPopover) {
                            let song = player.song!
                            let sampleRate = String(format: "%g", Double(song.sampleRate) / 1000)
                            Text("\(song.bitDepth) bit/\(sampleRate) kHz").padding(10)
                        }
                        .frame(width: 40)
                        VStack(alignment: .leading) {
                            Group {
                                Text($player.song.wrappedValue!.title).bold()
                                Text($player.song.wrappedValue!.artist).foregroundColor(.secondary)
                            }.frame(maxWidth: 400, alignment: .leading)
                        }
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
