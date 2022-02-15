//
//  IyokanApp.swift
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

import SwiftUI

@main
struct IyokanApp: App {
    @StateObject var dataStorage = DataStorage.shared

    var body: some Scene {
        WindowGroup {
            ContentView(dataStorage: dataStorage)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .commands {
            CommandMenu("Playback") {
                Button("Play/pause") {
                    Player.shared.play()
                }
                .disabled(dataStorage.selectedPlaylist == nil)
                .keyboardShortcut(" ", modifiers: [])       // this shortcut doesn't work
            }
            CommandGroup(replacing: .newItem) {
                Button("New Playlist") {
                    dataStorage.newPlaylist()
                }
                .keyboardShortcut("n")
                Button("Add Files") {
                    dataStorage.selectedPlaylist?.openFile()
                }
                .disabled(dataStorage.selectedPlaylist == nil)
                .keyboardShortcut("o")
            }
        }
    }
}
