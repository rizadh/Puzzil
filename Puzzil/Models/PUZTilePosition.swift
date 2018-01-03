//
//  PUZTilePosition.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-02.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct PUZTilePosition {
    let row: Int
    let column: Int

    static func distanceBetween(_ a: PUZTilePosition, _ b: PUZTilePosition) -> Int {
        return abs(a.row - b.row) + abs(a.column - b.column)
    }

    func isAdjacentTo(_ otherPosition: PUZTilePosition) -> Bool {
        return PUZTilePosition.distanceBetween(self, otherPosition) == 1
    }
}
