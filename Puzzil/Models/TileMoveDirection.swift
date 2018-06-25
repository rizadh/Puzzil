//
//  TileMoveDirection.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-07.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

enum TileMoveDirection {
    case up, down, right, left

    // TODO: Replace with Swift 4.2 CaseIterable conformance when possible
    static let allCases = [up, down, right, left]

    var opposite: TileMoveDirection {
        switch self {
        case .up:
            return .down
        case .down:
            return .up
        case .left:
            return .right
        case .right:
            return .left
        }
    }
}
