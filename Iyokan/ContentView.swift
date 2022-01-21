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

    @ObservedObject var dataStorage: DataStorage

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(dataStorage.playlists) { playlist in
                        NavigationLink(destination: PlaylistView(playlist: playlist), tag: playlist, selection: $dataStorage.selectedPlaylist) {
                            Label(playlist.name, systemImage: "music.note.list")
                        }
                    }
                }
                .navigationTitle("SwiftUI")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: toggleSidebar, label: {
                            Image(systemName: "sidebar.left")
                        }).controlSize(.large)
                    }
                }
                .listStyle(.sidebar)
                Divider()
                HStack {
                    Button(action: {
                        dataStorage.append(Playlist(name: "New Playlist", items: nil))
                    }) {
                        Image(systemName: "plus")
                    }.buttonStyle(.borderless).padding([.horizontal, .bottom], 6)
                    Spacer()
                    Button(action: {
                        dataStorage.remove(nil)
                    }) {
                        Image(systemName: "minus")
                    }.buttonStyle(.borderless).padding([.horizontal, .bottom], 6)
                }
            }
        }.onAppear {
            // select = playlists[0]
        }
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }

}
