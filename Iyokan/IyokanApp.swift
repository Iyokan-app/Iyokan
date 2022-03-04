//
//  IyokanApp.swift
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

import SwiftUI
import MediaPlayer

@main
struct IyokanApp: App {
    @StateObject var dataStorage = DataStorage.shared
    let player = Player.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStorage)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false

                    let commandCenter = MPRemoteCommandCenter.shared()
                    commandCenter.playCommand.addTarget { _ in
                        player.play()
                        return .success
                    }
                    commandCenter.pauseCommand.addTarget { _ in
                        player.pause()
                        return .success
                    }
                    commandCenter.togglePlayPauseCommand.addTarget { _ in
                        player.toggle()
                        return .success
                    }
                    commandCenter.nextTrackCommand.addTarget { _ in
                        player.next()
                        return .success
                    }
                    commandCenter.previousTrackCommand.addTarget { _ in
                        player.previous()
                        return .success
                    }
                    commandCenter.changePlaybackPositionCommand.addTarget { event in
                        guard let position = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime else { return .commandFailed }
                        player.seekToOffset(.init(seconds: position, preferredTimescale: CMTimePreferredTimescale))
                        return .success
                    }
                }
        }
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .commands {
            CommandMenu("Playback") {
                Button("Toggle Play/Pause") {
                    Player.shared.toggle()
                }
                .disabled(dataStorage.selectedPlaylist == nil)
                .keyboardShortcut(" ", modifiers: [])       // this shortcut doesn't work
                Button("Next Song") {
                    Player.shared.next()
                }
                .disabled(dataStorage.selectedPlaylist == nil)
                Button("Previous Song") {
                    Player.shared.previous()
                }
                .disabled(dataStorage.selectedPlaylist == nil)
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
//            CommandGroup(replacing: .appSettings) {
//                Button("Preferences…") {
//
//                }
//                .keyboardShortcut(",")
//            }
        }

        Settings {
            PreferencesView()
        }
    }
}
