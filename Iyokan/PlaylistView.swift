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
        let tableView = IKTableView()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true

        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.target = context.coordinator
        tableView.doubleAction = #selector(PlaylistViewController.doubleAction(sender:))
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true

        // configuring columns
        let col = makeColumn(id: "playing", title: " ")
        col.width = 10
        tableView.addTableColumn(col)

        let col1 = makeColumn(id: "trackNo", title: "#")
        col1.width = 10
        tableView.addTableColumn(col1)

        let col2 = makeColumn(id: "artist", title: "Artist")
        col2.minWidth = 100
        tableView.addTableColumn(col2)

        let col3 = makeColumn(id: "title", title: "Title")
        col3.minWidth = 100
        tableView.addTableColumn(col3)

        dataStorage.selectedPlaylist?.playlistView = tableView

        return scrollView
    }

    private func makeColumn(id: String, title: String) -> NSTableColumn {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: id))
        column.title = title
        column.isEditable = false
        return column
    }

    func makeCoordinator() -> PlaylistViewController {
        return PlaylistViewController(playlist: dataStorage.selectedPlaylist!)
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        (scrollView.documentView as! NSTableView).reloadData()
    }
}

@objc
class PlaylistViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    let playlist: Playlist

    init(playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // target actions
    @objc func doubleAction(sender: AnyObject) {
        let tableView = playlist.playlistView!
        guard tableView.clickedRow != -1 else { return }

        Player.shared.seekToItem(playlist.items[tableView.clickedRow])
    }

    @objc func addFiles(sender: AnyObject) {
        playlist.openFile()
    }

    func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        menu.insertItem(withTitle: "Add Files", action: #selector(addFiles(sender:)), keyEquivalent: "o", at: 0).target = self

        if let clickedRow = playlist.playlistView?.clickedRow, clickedRow != -1 {
            let clickedItem = playlist.items[clickedRow]
            menu.insertItem(withTitle: "Play \(clickedItem.song.title)", action: #selector(doubleAction(sender:)), keyEquivalent: "", at: 0).target = self
        }
        return menu
    }

    // NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return playlist.items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = playlist.items[row]

        let text = NSTextField()
        let view = NSView()
        switch tableColumn?.identifier.rawValue {
        case "playing":
            if !item.isEnqueued { return nil }
            return NSImageView(image: .init(systemSymbolName: "play.fill", accessibilityDescription: nil)!)
        case "trackNo":
            text.stringValue = String(item.song.trackNo)
        case "title":
            text.stringValue = item.song.title
        case "artist":
            text.stringValue = item.song.artist
        default:
            break
        }
        view.addSubview(text)
        text.drawsBackground = false
        text.isBordered = false
        text.isEditable = false
        text.cell?.wraps = false
        text.maximumNumberOfLines = 1
        text.cell?.lineBreakMode = .byTruncatingTail
        // text.cell?.truncatesLastVisibleLine = true
        text.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: text, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: text, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: text, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0))
        return view
    }

    // NSTableViewDelegate
}

class IKTableView: NSTableView {
    override func menu(for event: NSEvent) -> NSMenu? {
        super.menu(for: event)
        return (self.target as! PlaylistViewController).menu(for: event)
    }
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
