//
//  Player.swift
//  Iyokan
//
//  Created by uiryuu on 3/2/2022.
//

import Foundation

class Player: ObservableObject {
    var serializer = Serializer()

    @Published var percentage: Double = 0
}
