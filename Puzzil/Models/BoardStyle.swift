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
    case compass
    case vortex
    case fifteen
    case cyclone

    // TODO: Replace with Swift 4.2 CaseIterable conformance when possible
    static let allCases = [original, telephone, compass, vortex, fifteen, cyclone]

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
        case .compass:
            return Board(matrix: [
                ["NW", "N", "NE"],
                ["W", nil, "E"],
                ["SW", "S", "SE"],
            ])
        case .vortex:
            return Board(matrix: [
                [8, 1, 2],
                [7, nil, 3],
                [6, 5, 4],
            ])
        case .fifteen:
            return Board(matrix: [
                [1, 2, 3, 4],
                [5, 6, 7, 8],
                [9, 10, 11, 12],
                [13, 14, 15, nil],
            ])
        case .cyclone:
            return Board(matrix: [
                [9, 10, 11, 12],
                [8, 1, 2, 13],
                [7, nil, 3, 14],
                [6, 5, 4, 15],
            ])
        }
    }
}
