//
//  ContentView.swift
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

import SwiftUI
import Foundation
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var dataStorage: DataStorage

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(dataStorage.playlists) { playlist in
                        NavigationLink(destination: MainView(), tag: playlist, selection: $dataStorage.selectedPlaylist) {
                            HStack {
                                Image(systemName: "music.note.list")
                                TextField(playlist.name, text: Binding(get: {playlist.name}, set: {playlist.name = $0}))
                                    .disabled(playlist != $dataStorage.selectedPlaylist.wrappedValue)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: toggleSidebar, label: {
                            Image(systemName: "sidebar.left")
                        })
                        .controlSize(.large)
                    }
                }
                Divider()
                HStack {
                    Button(action: {
                        dataStorage.newPlaylist()
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    .padding([.horizontal, .bottom], 6)
                    Spacer()
                    Button(action: {
                        dataStorage.remove(nil)
                    }) {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.borderless)
                    .padding([.horizontal, .bottom], 6)
                }
            }
        }
        .onAppear {
            // select = playlists[0]
        }
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }

}

struct MainView: View {
    @EnvironmentObject var dataStorage: DataStorage
    @ObservedObject var player = Player.shared

    var body: some View {
        VStack(spacing: 0) {
            PlayerView()
            RepresentedPlaylistView()
                .toolbar {
                    ToolbarItemGroup {
                        Slider(value: $player.volume, in: 0...1) {}
                        minimumValueLabel: {
                            Image(systemName: "speaker.slash.fill")
                        }
                        maximumValueLabel: {
                            Image(systemName: "speaker.wave.3.fill")
                        }
                        .frame(width: 120)
                        .controlSize(.small)
                        Button(action: { dataStorage.selectedPlaylist?.openFile() }) {
                            Image(systemName: "doc.badge.plus")
                        }
                        .controlSize(.large)
                    }
                }
        }
        .frame(minWidth: 900, minHeight: nil, idealHeight: nil, maxHeight: nil)
    }
}
