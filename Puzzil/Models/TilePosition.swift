//
//  TilePosition.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-02.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct TilePosition {
    let row: Int
    let column: Int

    static func distanceBetween(_ a: TilePosition, _ b: TilePosition) -> Int {
        return abs(a.row - b.row) + abs(a.column - b.column)
    }

    func isAdjacentTo(_ otherPosition: TilePosition) -> Bool {
        return TilePosition.distanceBetween(self, otherPosition) == 1
    }
}

extension TilePosition: Equatable {
    static func == (lhs: TilePosition, rhs: TilePosition) -> Bool {
        return lhs.row == rhs.row && lhs.column == rhs.column
    }
}
