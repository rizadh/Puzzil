//
//  PUZTile.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-24.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import Foundation

struct PUZTile {
    let targetRow: Int
    let targetColumn: Int
    let text: String

    func distance(from currentRow: Int, currentColumn: Int) -> Int {
        return abs(currentRow - targetRow) + abs(currentColumn - targetColumn)
    }
}
