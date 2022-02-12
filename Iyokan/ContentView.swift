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
                        NavigationLink(destination: MainView(), tag: playlist, selection: $dataStorage.selectedPlaylist) {
                            Label(playlist.name, systemImage: "music.note.list")
                        }
                    }
                }
                .listStyle(.sidebar)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: toggleSidebar, label: {
                            Image(systemName: "sidebar.left")
                        }).controlSize(.large)
                    }
                }
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
        }.environmentObject(dataStorage)
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }

}

struct MainView: View {
    var body: some View {
        VStack {
            PlayerView()
            RepresentedPlaylistView()
                .toolbar {
                    ToolbarItem() {
                        Spacer()
                    }
                    ToolbarItem() {
                        Button(action: { DataStorage.shared.selectedPlaylist?.openFile() }) {
                            Image(systemName: "doc.badge.plus")
                        }.controlSize(.large)
                    }
                }
        }
    }
}
