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

    var playlists: some View {
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

    var tempPlaylist: some View {
        let tempPlaylist = dataStorage.tempPlaylist
        return NavigationLink(destination: MainView(), isActive: dataStorage.selectionBindingForId(id: tempPlaylist.id)) {
            Label("Temporary Playlist", systemImage: "list.bullet.rectangle.portrait")
        }
        .contextMenu {
            Button {
                tempPlaylist.removeItems(indexes: .init(integersIn: 0 ..< tempPlaylist.items.count))
            } label: {
                Text("Empty Temporary Playlist")
            }
        }
    }


    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Temp")) {
                        tempPlaylist
                    }
                    Section(header: Text("Playlists")) {
                        playlists
                    }
                    Section(header: Text("m3u Playlists")) {
                        // localPlaylists
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
                    Menu {
                        Button("Create a New Playlist") {
                            dataStorage.newPlaylist()
                        }
                        Button("Open a m3u Playlist…") {
                            let openPanel = NSOpenPanel()
                            openPanel.allowedContentTypes = [.m3uPlaylist]
                            openPanel.allowsMultipleSelection = true
                            openPanel.canChooseDirectories = false
                            openPanel.canChooseFiles = true
                            openPanel.beginSheetModal(for: NSApp.keyWindow!) {_ in
                            }
                        }
                    } label: {
                        Label("New Playlist", systemImage: "plus.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
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
