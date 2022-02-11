//
//  PlaylistView.swift
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

import Foundation
import SwiftUI
import AVFoundation
import Cocoa

struct RepresentedPlaylistView: NSViewRepresentable {
    let dataStorage = DataStorage.shared

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator

        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "trackNo"))
        col1.title = "#"
        col1.width = 10
        tableView.addTableColumn(col1)

        let col3 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "artist"))
        col3.title = "Artist"
        col3.minWidth = 50
        tableView.addTableColumn(col3)

        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "title"))
        col2.title = "Title"
        col2.minWidth = 50
        tableView.addTableColumn(col2)

        dataStorage.selectedPlaylist?.playlistView = tableView

        return scrollView
    }

    func makeCoordinator() -> PlaylistViewController {
        return PlaylistViewController(playlist: dataStorage.selectedPlaylist!)
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        (scrollView.documentView as! NSTableView).reloadData()
    }
}

class PlaylistViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    let playlist: Playlist

    init(playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return playlist.items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = playlist.items[row]

        let text = NSTextField()
        let cell = NSView()
        switch tableColumn?.identifier.rawValue {
        case "trackNo":
            text.stringValue = String(item.song.trackNo)
        case "title":
            text.stringValue = item.song.title
        case "artist":
            text.stringValue = item.song.artist
        default:
            break
        }
        cell.addSubview(text)
        text.drawsBackground = false
        text.isBordered = false
        text.translatesAutoresizingMaskIntoConstraints = false
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0))
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .left, relatedBy: .equal, toItem: cell, attribute: .left, multiplier: 1, constant: 0))
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .right, relatedBy: .equal, toItem: cell, attribute: .right, multiplier: 1, constant: 0))
        return cell
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.isEmphasized = false
        return rowView
    }
    // NSTableViewDelegate

}

//struct PlaylistView: View {
//    @EnvironmentObject var dataStorage: DataStorage
//
//    @State private var selectedItems = Set<Item.ID>()
//    @State private var sortOrder = [KeyPathComparator(\Item.song.trackNo)]
//    @State private var position: Double = 0
//
//    @State private var hovering: [Item] = []
//
//    private var player = Player.shared
//
//    func openFile() {
//        guard let playlist = dataStorage.selectedPlaylist else { return }
//        let openPanel = NSOpenPanel()
//        openPanel.allowedContentTypes = [.audio]
//        openPanel.allowsMultipleSelection = true
//        openPanel.canChooseDirectories = false
//        openPanel.canChooseFiles = true
//        openPanel.beginSheetModal(for: NSApp.keyWindow!) {_ in
//            playlist.addMedia(urls: openPanel.urls)
//            dataStorage.objectWillChange.send()
//        }
//    }
//
//    var body: some View {
//        VStack {
//            GeometryReader { geometry in
//                Table(dataStorage.selectedPlaylist!.items, selection: $selectedItems, sortOrder: $sortOrder) {
//                    TableColumn("#", value: \.song.trackNo) { row in
//                        Text(String(row.song.trackNo))
//                            // Extend the length of the text view to detect the cursor
//                            // 24 is the default height of a NSTableView row
//                            .frame(width: geometry.size.width, height: 24, alignment: .leading)
//                            .onHover() { inside in
//                                if inside {
//                                    if self.hovering.count > 2 {
//                                        _ = self.hovering.dropFirst()
//                                    }
//                                    self.hovering.append(row)
//                                } else {
//                                    self.hovering.removeAll(where: { $0 == row })
//                                }
//                            }
//                    }
//                    .width(20)
//                    TableColumn("Title", value: \.song.title)
//                    TableColumn("Artist", value: \.song.artist)
//                }
//                .contextMenu {
//                    Button("Add Files") {
//                        openFile()
//                    }
//                    if $hovering.count != 0 {
//                        let item = hovering.last!
//                        Button("Play \(item.song.title)") {
//                            player.seekToItem(item)
//                        }
//                    }
//                }
//                .onChange(of: sortOrder) {
//                    dataStorage.selectedPlaylist!.items.sort(using: $0)
//                }
//                .toolbar {
//                    ToolbarItem() {
//                        Spacer()
//                    }
//                    ToolbarItem() {
//                        Button(action: openFile) {
//                            Image(systemName: "doc.badge.plus")
//                        }.controlSize(.large)
//                    }
//                }
//            }
//        }
//    }
//}
