//
//  BoardStyle.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-05-23.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

enum BoardStyle: String {
    case original
    case telephone
    case arrows
    case vortex

    static var all = [original, telephone, arrows, vortex]

    var targetScrambleProgress: Double {
        switch self {
        case .original, .telephone, .arrows:
            return 0
        case .vortex:
            return 0.5
        }
    }

    var board: Board {
        switch self {
        case .original:
            return Board(matrix: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, nil],
            ])
        case .telephone:
            return Board(matrix: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
                [nil, 0, nil],
            ])
        case .arrows:
            return Board(matrix: [
                ["↖", "↑", "↗"],
                ["←", nil, "→"],
                ["↙", "↓", "↘"],
            ])
        case .vortex:
            return Board(matrix: [
                [24, 9, 10, 11, 12],
                [23, 8, 1, 2, 13],
                [22, 7, nil, 3, 14],
                [21, 6, 5, 4, 15],
                [20, 19, 18, 17, 16],
            ])
        }
    }
}
