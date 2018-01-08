//
//  Board.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-23.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import Foundation

struct Board {
    let rows: Int
    let columns: Int
    private var tiles = [[Tile?]]()

    var isSolved: Bool {
        for (rowIndex, row) in tiles.enumerated() {
            for (columnIndex, element) in row.enumerated() {
                guard let tile = element else { continue }

                if tile.target != TilePosition(row: rowIndex, column: columnIndex) {
                    return false
                }
            }
        }

        return true
    }

    init(from matrix: [[CustomStringConvertible?]]) {
        precondition(matrix.count > 0, "Matrix must have at least one row")
        precondition(matrix.first!.count > 0, "Matrix must have at least one column")

        rows = matrix.count
        columns = matrix.first!.count

        tiles.reserveCapacity(rows)

        for (columnIndex, row) in matrix.enumerated() {
            precondition(columns == row.count, "Provided matrix does not have a consistent row length")

            var tileRow = [Tile?]()
            tileRow.reserveCapacity(columns)

            for (rowIndex, element) in row.enumerated() {
                let tile: Tile?

                if let element = element {
                    tile = Tile(target: TilePosition(row: rowIndex, column: columnIndex), text: element.description)
                } else {
                    tile = nil
                }

                tileRow.append(tile)
            }

            tiles.append(tileRow)
        }
    }

    func boardContains(_ position: TilePosition) -> Bool {
        return position.row >= 0 && position.row < rows &&
            position.column >= 0 && position.column < columns
    }

    func tileIsPresent(at position: TilePosition) -> Bool? {
        guard boardContains(position) else { return nil }

        return tiles[position] != nil
    }

    func canMoveTile(at position: TilePosition, _ direction: TileMoveDirection) -> Bool? {
        let target = position.moved(direction)

        guard let tileIsPresentAtSource = tileIsPresent(at: position) else { return nil }

        guard let _ = tileIsPresent(at: target) else { return nil }

        if !tileIsPresentAtSource { return false }

        var currentPosition = target

        while (currentPosition != position) {
            if tileIsPresent(at: currentPosition)! { return false }

            currentPosition = target.moved(direction.opposite)
        }

        return true
    }

    func textOfTile(at position: TilePosition) -> String? {
        precondition(boardContains(position))

        return tiles[position]?.text
    }

    mutating func moveTile(at position: TilePosition, _ direction: TileMoveDirection) {
        guard let tileIsMovable = canMoveTile(at: position, direction) else {
            fatalError("Move operation exceeds the bounds of the board")
        }

        precondition(tileIsMovable, "Tile cannot be moved to desired position")

        let targetPosition = position.moved(direction)

        tiles[targetPosition] = tiles[position]
        tiles[position] = nil
    }
}

extension Array where Element == Array<Tile?> {
    subscript(_ position: TilePosition) -> Tile? {
        get {
            return self[position.row][position.column]
        }

        set {
            self[position.row][position.column] = newValue
        }
    }
}

