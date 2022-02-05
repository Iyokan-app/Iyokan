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
        }.toolbar {
            ToolbarItem() {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                }).controlSize(.large)
            }
            ToolbarItem() {
                Spacer()
            }
            ToolbarItem() {
                Button(action: openFile, label: {
                    Image(systemName: "plus")
                }).controlSize(.large)
            }
        }.environmentObject(dataStorage)
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
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

}

struct MainView: View {
    var body: some View {
        VStack {
            PlaylistView()
            PlayerView()
        }
    }
}
