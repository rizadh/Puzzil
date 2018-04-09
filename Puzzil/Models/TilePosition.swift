//
//  TilePosition.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-02.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct TilePosition: Equatable, Hashable {
    var row: Int
    var column: Int

    var possibleOperations: [TileMoveOperation] {
        return [
            TileMoveOperation(moving: .left, from: self),
            TileMoveOperation(moving: .right, from: self),
            TileMoveOperation(moving: .up, from: self),
            TileMoveOperation(moving: .down, from: self),
        ]
    }

    static func distanceBetween(_ a: TilePosition, _ b: TilePosition) -> Int {
        return abs(a.row - b.row) + abs(a.column - b.column)
    }

    static func traversePositions(rows: Int, columns: Int) -> TilePositionIterator {
        return TilePositionIterator(rows: rows, columns: columns)
    }

    func distance(to otherPosition: TilePosition) -> Int {
        return TilePosition.distanceBetween(self, otherPosition)
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

struct TilePositionIterator: Sequence, IteratorProtocol {
    private let columns: Int
    private let rows: Int
    private var count = 0

    fileprivate init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
    }

    mutating func next() -> TilePosition? {
        if count < columns * rows {
            defer { count += 1 }
            return TilePosition(row: count / columns, column: count % columns)
        } else {
            return nil
        }
    }
}
