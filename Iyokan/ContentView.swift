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

    @State private var renaming: Playlist? = nil
    @State private var name: String = ""
    @FocusState private var textFieldFocused

    var list: some View {
        ForEach(dataStorage.playlists) { playlist in
            NavigationLink(destination: MainView(), isActive: dataStorage.selectionBindingForId(id: playlist.id)) {
                HStack {
                    if renaming == playlist {
                        Image(systemName: "music.note.list")
                        TextField("Playlist Name", text: $name)
                            .focused($textFieldFocused)
                            .onChange(of: textFieldFocused) { focused in
                                if !focused {
                                    renaming = nil
                                    playlist.name = name
                                }
                            }
                    } else {
                        Label(playlist.name, systemImage: "music.note.list")
                    }
                }
            }
            .contextMenu {
                Button {
                    renaming = playlist
                    textFieldFocused = true
                    name = playlist.name
                } label: {
                    Text("Rename")
                }
                Button {
                    dataStorage.remove(playlist)
                } label: {
                    Text("Delete \(playlist.name)")
                }
            }
        }
        .onMove(perform: dataStorage.movePlaylists)
    }

    var body: some View {
        NavigationView {
            VStack {
                List {
                    list
                }
                .contextMenu {
                    Button {
                        dataStorage.newPlaylist()
                    } label: {
                        Text("New Playlist")
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: toggleSidebar, label: {
                            Image(systemName: "sidebar.left")
                        })
                        .controlSize(.large)
                    }
                }
                HStack {
                    Button(action: {
                        dataStorage.newPlaylist()
                    }) {
                        Label("New Playlist", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderless)
                    .padding([.horizontal, .bottom], 6)
                    Spacer()
                    Button(action: {
                        dataStorage.remove(nil)
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .padding([.horizontal, .bottom], 6)
                }
            }
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
