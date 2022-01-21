//
//  IyokanApp.swift
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

import SwiftUI

@main
struct DimkoApp: App {
    @StateObject var dataStorage = DataStorage()

    var body: some Scene {
        WindowGroup {
            ContentView(dataStorage: dataStorage)
        }.windowToolbarStyle(.unifiedCompact(showsTitle: false))
    }
}
