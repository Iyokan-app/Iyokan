//
//  AppData.swift
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

import Foundation

let allowedTypes = ["mp3", "wav", "flac", "m4a", "tta", "aiff", "opus", "ogg", "wv"]

let CMTimePreferredTimescale: Int32 = 1000

let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
let storageURL = supportDir.appendingPathComponent("storage.plist")

struct AppStorageKeys {
    static let volume = "volume"
}
