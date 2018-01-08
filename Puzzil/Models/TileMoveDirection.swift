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

    init?(from swipeDirection: UISwipeGestureRecognizerDirection) {
        if swipeDirection.contains(.left) {
            self = .left
        } else if swipeDirection.contains(.right) {
            self = .right
        }

        switch swipeDirection {
        case .left:
            self = .left
        case .right:
            self = .right
        case .up:
            self = .up
        case .down:
            self = .down
        default:
            return nil
        }
    }
}
