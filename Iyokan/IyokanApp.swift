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
            CommandGroup(replacing: .newItem) {
                Button("New Playlist") {
                    dataStorage.newPlaylist()
                }.keyboardShortcut("n")
            }
        }
    }
}
