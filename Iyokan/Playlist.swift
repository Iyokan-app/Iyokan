//
//  Playlist.swift
//  Iyokan
//
//  Created by uiryuu on 2021/07/06.
//

import Cocoa

class Playlist: Identifiable, Hashable {
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

    func setCurrnetIndex(id: UUID) {
        for i in 0 ..< items.count {
            if items[i].id == id {
                currentIndex = i
                return
            }
        }
        currentIndex = nil
    }

    func removeItems(indexes: IndexSet) {
        indexes.enumerated().reversed().forEach {
            items.remove(at: $0.element)
        }
        itemsHasChanged()
    }

    func move(with indexSet: IndexSet, to dest: Int) {
        items.move(fromOffsets: indexSet, toOffset: dest)
        itemsHasChanged()
    }

    func addMedia(urls: [URL], at offset: Int? = nil) {
        var offset = offset ?? items.count
        urls.forEach{
            let song = Song($0.path)
            items.insert(Item(song: song, fromOffset: .zero, playlist: self), at: offset)
            offset += 1
        }
        itemsHasChanged()
    }

    private func itemsHasChanged() {
        Player.shared.continueWithCurrentItems()
        playlistView?.reloadData()
    }

    let id = UUID()
    var name: String = ""
    var items: [Item] = []

    // nil if the player is in a stopped state
    var currentIndex: Int?
    var currentItem: Item? {
        guard let index = currentIndex else { return nil }
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }
    var currentSong: Song? { currentItem?.song ?? nil }

    var playlistView: NSTableView? = nil
}
