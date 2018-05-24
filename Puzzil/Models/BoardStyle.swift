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

    static var all = [original, telephone, arrows]

    var board: Board {
        switch self {
        case .original:
            return Board(from: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, nil],
            ])
        case .telephone:
            return Board(from: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
                [nil, 0, nil],
            ])
        case .arrows:
            return Board(from: [
                ["↖", "↑", "↗"],
                ["←", nil, "→"],
                ["↙", "↓", "↘"],
            ])
        }
    }
}
