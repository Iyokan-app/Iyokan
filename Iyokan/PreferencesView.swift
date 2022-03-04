//
//  PreferencesView.swift
//  Iyokan
//
//  Created by Yuze Jiang on 4/3/2022.
//

import SwiftUI

struct PreferencesView: View {

    private enum Tabs: Hashable {
        case general, playback
    }

    var body: some View {
        TabView {
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            PlaybackPreferencesView()
                .tabItem {
                    Label("Playback", systemImage: "music.note")
                }
                .tag(Tabs.playback)
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
