//
//  BoardStyle.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-05-23.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

enum BoardStyle: String, CaseIterable {
    case original
    case telephone
    case arrows
    case vortex

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
                [8, 1, 2],
                [7, nil, 3],
                [6, 5, 4],
            ])
        }
    }
}
