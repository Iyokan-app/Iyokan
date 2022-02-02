//
//  Extensions.swift
//  Iyokan
//
//  Created by uiryuu on 2/2/2022.
//

import Foundation

extension CMTime: CustomStringConvertible {
    public var description: String {
        return "\(self.seconds) seconds"
    }

    static func += (lhs: inout CMTime, rhs: CMTime) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout CMTime, rhs: CMTime) {
        lhs = lhs - rhs
    }

}
