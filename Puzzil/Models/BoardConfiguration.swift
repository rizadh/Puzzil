//
//  BoardConfiguration.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-22.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct BoardConfiguration {
    static let builtins = [
        BoardConfiguration(name: "original", matrix: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, nil],
        ]),
        BoardConfiguration(name: "telephone", matrix: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
            [nil, 0, nil],
        ]),
//        BoardConfiguration(name: "puzzil", matrix: [
//            ["P", "U", "Z"],
//            ["Z", "I", "L"],
//            ["L", nil, nil],
//        ]),
    ]

    let name: String
    let matrix: [[CustomStringConvertible?]]
}
