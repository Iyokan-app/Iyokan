//
//  Playlist.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/06.
//

import Cocoa

class Playlist: Identifiable, ObservableObject, Hashable {
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }

    init(name: String, items: [Item]?) {
        self.name = name
        self.items = items ?? []
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func openFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.audio]
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.beginSheetModal(for: NSApp.keyWindow!) {_ in
            self.addMedia(urls: openPanel.urls)
            DataStorage.shared.objectWillChange.send()
        }
    }

    private func addMedia(urls: [URL]) {
        urls.forEach{
            let song = Song($0.path)
            items.append(Item(song: song, fromOffset: .zero, playlist: self))
        }
        objectWillChange.send()
        Player.shared.continueWithCurrentItems()
        playlistView?.reloadData()
    }

    func setCurrnetIndex(id: UUID) {
        for i in 0 ..< items.count {
            if items[i].id == id {
                currentIndex = i
                return
            }
        }
        currentIndex = nil
    }

    let id = UUID()
    var name: String = ""
    var items: [Item] = []
    // nil if the player is in a stopped state
    var currentIndex: Int?

    var playlistView: NSTableView? = nil
}
