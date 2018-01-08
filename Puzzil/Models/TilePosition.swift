//
//  TilePosition.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-02.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct TilePosition {
    var row: Int
    var column: Int

    static func distanceBetween(_ a: TilePosition, _ b: TilePosition) -> Int {
        return abs(a.row - b.row) + abs(a.column - b.column)
    }

    static func traversePositions(boundedBy position: TilePosition, _ body: (TilePosition) throws -> Void) rethrows {
        for rowIndex in 0..<position.row {
            for columnIndex in 0..<position.column {
                try body(TilePosition(row: rowIndex, column: columnIndex))
            }
        }
    }

    func isAdjacentTo(_ otherPosition: TilePosition) -> Bool {
        return TilePosition.distanceBetween(self, otherPosition) == 1
    }

    func moved(_ direction: TileMoveDirection, by stride: Int = 1) -> TilePosition {
        switch direction {
        case .left:
            return TilePosition(row: row, column: column - stride)
        case .right:
            return TilePosition(row: row, column: column + stride)
        case .up:
            return TilePosition(row: row - stride, column: column)
        case .down:
            return TilePosition(row: row + stride, column: column)
        }
    }
}

extension TilePosition: Equatable {
    static func == (lhs: TilePosition, rhs: TilePosition) -> Bool {
        return lhs.row == rhs.row && lhs.column == rhs.column
    }
}
