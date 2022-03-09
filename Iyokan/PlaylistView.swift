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

enum TableViewColumnID: String {
    case playing, trackNo, title, artist, album
}

struct RepresentedPlaylistView: NSViewRepresentable {
    let dataStorage = DataStorage.shared

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        tableView.registerForDraggedTypes([.tableViewIndex, .fileURL])

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
        tableView.addTableColumn(makeColumn(id: TableViewColumnID.playing.rawValue, title: " ", width: 10))
        tableView.addTableColumn(makeColumn(id: TableViewColumnID.trackNo.rawValue, title: "#", minWidth: 15, maxWidth: 15))
        tableView.addTableColumn(makeColumn(id: TableViewColumnID.title.rawValue, title: "Title", minWidth: 200))
        tableView.addTableColumn(makeColumn(id: TableViewColumnID.artist.rawValue, title: "Artist", minWidth: 200))
        tableView.addTableColumn(makeColumn(id: TableViewColumnID.album.rawValue, title: "Album", minWidth: 200))

        dataStorage.selectedPlaylist?.playlistView = tableView

        return scrollView
    }

    private func makeColumn(id: String, title: String, minWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, width: CGFloat? = nil) -> NSTableColumn {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: id))
        column.title = title
        column.isEditable = false

        if let minWidth = minWidth {
            column.minWidth = minWidth
        }
        if let maxWidth = maxWidth {
            column.maxWidth = maxWidth
        }
        if let width = width {
            column.width = width
        }
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
        case TableViewColumnID.playing.rawValue:
            if playlist.currentItem != item { return nil }
            return NSImageView(image: .init(systemSymbolName: "play.fill", accessibilityDescription: nil)!)
        case TableViewColumnID.trackNo.rawValue:
            text.stringValue = String(song.trackNo)
        case TableViewColumnID.title.rawValue:
            text.stringValue = song.title
        case TableViewColumnID.artist.rawValue:
            text.stringValue = song.artist
        case TableViewColumnID.album.rawValue:
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

        if let source = info.draggingSource as? NSTableView, source === tableView {
            // dragging from playlist
            // tableView.draggingDestinationFeedbackStyle = .gap
            return .move
        }
        // dragging from outside Iyokan
        // tableView.draggingDestinationFeedbackStyle = .regular
        let pasteboard = info.draggingPasteboard
        if pasteboard.types?.contains(.fileURL) ?? false {
            guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [NSURL] else { return [] }
            let filtered = urls.filter{ allowedTypes.contains($0.pathExtension ?? "") }
            return filtered.isEmpty ? [] : .copy
        }
        return .copy
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard
        guard let items = pasteboard.pasteboardItems else { return false }
        guard let types = pasteboard.types else { return false }
        if types.contains(.fileURL) {
            guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [NSURL] else { return false }
            let filtered = urls.filter{ allowedTypes.contains($0.pathExtension ?? "") }
            playlist.addMedia(urls: filtered.compactMap{ $0.absoluteURL }, at: row)
            return true
        } else if types.contains(.tableViewIndex) {
            let indexes = items.compactMap{ $0.propertyList(forType: .tableViewIndex) as? Int }
            if !indexes.isEmpty {
                playlist.move(with: IndexSet(indexes), to: row)
                tableView.reloadData()
            }
            return true
        }

        return false
    }
}

extension PlaylistViewController: NSTableViewDelegate {
//    // according to https://www.natethompson.io/2019/03/23/nstableview-drag-and-drop.html
//    // not writing this will cause a bug in NSTableView .gap feedback animation
//    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//        return tableView.rowHeight
//    }
}
