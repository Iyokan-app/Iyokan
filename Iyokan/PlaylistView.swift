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

extension NSPasteboard.PasteboardType {
    static let tableViewIndex = NSPasteboard.PasteboardType("io.iyokan-app.iyokan.playlist.index")
}

struct RepresentedPlaylistView: NSViewRepresentable {
    let dataStorage = DataStorage.shared

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        tableView.registerForDraggedTypes([.tableViewIndex])

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
        tableView.autosaveTableColumns = true

        let menu = NSMenu()
        tableView.menu = menu
        menu.delegate = context.coordinator

        // configuring columns
        let col = makeColumn(id: "playing", title: " ")
        col.width = 10
        tableView.addTableColumn(col)

        let col1 = makeColumn(id: "trackNo", title: "#")
        col1.minWidth = 15
        col1.maxWidth = 15
        tableView.addTableColumn(col1)

        let col3 = makeColumn(id: "title", title: "Title")
        col3.minWidth = 200
        tableView.addTableColumn(col3)

        let col2 = makeColumn(id: "artist", title: "Artist")
        col2.minWidth = 200
        tableView.addTableColumn(col2)

        let col4 = makeColumn(id: "album", title: "Album")
        col3.minWidth = 200
        tableView.addTableColumn(col4)

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
class PlaylistViewController: NSViewController {
    let playlist: Playlist

    lazy var tableView = playlist.playlistView!

    var selections: IndexSet {
        let clicked = tableView.clickedRow == -1 ? IndexSet() : IndexSet([tableView.clickedRow])
        return tableView.selectedRowIndexes.union(clicked)
    }

    init(playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func doubleAction(sender: AnyObject) {
        guard tableView.clickedRow != -1 else { return }

        Player.shared.seekToItem(playlist.items[tableView.clickedRow])
    }

    @objc func openFileLocation(sender: AnyObject) {
        let urls = selections.map {
            URL(fileURLWithPath: playlist.items[$0].song.path)
        }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    @objc func addFiles(sender: AnyObject) {
        playlist.openFile()
    }

    @objc func removeItems(sender: AnyObject) {
        playlist.removeItems(indexes: selections)
    }
}

extension PlaylistViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.insertItem(withTitle: "Add Files", action: #selector(addFiles(sender:)), keyEquivalent: "", at: 0).target = self
        if let clickedRow = playlist.playlistView?.clickedRow, clickedRow != -1 {
            let clickedItem = playlist.items[clickedRow]
            menu.insertItem(.separator(), at: 0)
            menu.insertItem(withTitle: "Open File Location", action: #selector(openFileLocation(sender:)), keyEquivalent: "", at: 0).target = self
            menu.insertItem(withTitle: "Remove Item(s)", action: #selector(removeItems(sender:)), keyEquivalent: "", at: 0).target = self
            menu.insertItem(withTitle: "Play \(clickedItem.song.title)", action: #selector(doubleAction(sender:)), keyEquivalent: "", at: 0).target = self
        }
    }
}

extension PlaylistViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return playlist.items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = playlist.items[row]

        let text = NSTextField()
        let view = NSView()
        let song = item.song
        switch tableColumn?.identifier.rawValue {
        case "playing":
            if !item.isEnqueued { return nil }
            return NSImageView(image: .init(systemSymbolName: "play.fill", accessibilityDescription: nil)!)
        case "trackNo":
            text.stringValue = String(song.trackNo)
        case "title":
            text.stringValue = song.title
        case "artist":
            text.stringValue = song.artist
        case "album":
            text.stringValue = song.album
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

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setPropertyList(row, forType: .tableViewIndex)
        return pasteboardItem
    }

    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {}

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard dropOperation == .above else { return [] }

//        if let source = info.draggingSource as? NSTableView, source === tableView {
//            tableView.draggingDestinationFeedbackStyle = .gap
//        } else {
//            tableView.draggingDestinationFeedbackStyle = .regular
//        }

        return .move
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let items = info.draggingPasteboard.pasteboardItems else { return false }
        let indexes = items.compactMap{ $0.propertyList(forType: .tableViewIndex) as? Int }
        if !indexes.isEmpty {
            playlist.move(with: IndexSet(indexes), to: row)
            tableView.reloadData()
        }
        return true
    }
}

extension PlaylistViewController: NSTableViewDelegate {
//    // according to https://www.natethompson.io/2019/03/23/nstableview-drag-and-drop.html
//    // not writing this will cause a bug in NSTableView .gap feedback animation
//    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//        return tableView.rowHeight
//    }
}
