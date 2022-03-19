//
//  GeneralPreferencesView.swift
//  Iyokan
//
//  Created by Yuze Jiang on 4/3/2022.
//

import SwiftUI

struct GeneralPreferencesView: View {
    @AppStorage(AppStorageKeys.clearDefaultPlaylist) var clearDefaultPlaylist: Bool = true

    var body: some View {
        Toggle("Clear the default playlist on quit", isOn: $clearDefaultPlaylist)
            .toggleStyle(.checkbox)
        // Text("General Preferences View", comment: "Do not translate")
    }
}

struct GeneralPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralPreferencesView()
    }
}
