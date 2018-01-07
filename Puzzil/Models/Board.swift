//
//  PUZBoard.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-23.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import Foundation

struct PUZBoard {
    let rows: Int
    let columns: Int
    private var tiles = [[PUZTile?]]()

    var isSolved: Bool {
        for (rowIndex, row) in tiles.enumerated() {
            for (columnIndex, element) in row.enumerated() {
                guard let tile = element else { continue }

                if tile.target != PUZTilePosition(row: rowIndex, column: columnIndex) {
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

            var tileRow = [PUZTile?]()
            tileRow.reserveCapacity(columns)

            for (rowIndex, element) in row.enumerated() {
                let tile: PUZTile?

                if let element = element {
                    tile = PUZTile(target: PUZTilePosition(row: rowIndex, column: columnIndex), text: element.description)
                } else {
                    tile = nil
                }

                tileRow.append(tile)
            }

            tiles.append(tileRow)
        }
    }

    func boardContains(_ position: PUZTilePosition) -> Bool {
        return position.row < rows && position.column < columns
    }

    func tileIsPresent(at position: PUZTilePosition) -> Bool? {
        guard boardContains(position) else { return nil }

        return tiles[position] != nil
    }

    func canMoveTile(at source: PUZTilePosition, to target: PUZTilePosition) -> Bool? {
        guard let tileIsPresentAtSource = tileIsPresent(at: source) else {
            assertionFailure("Checking a move from an out-of-bounds position")
            return nil
        }

        guard let tileIsPresentAtTarget = tileIsPresent(at: target) else {
            assertionFailure("Checking a move to an out-of-bounds position")
            return nil
        }

        return source.isAdjacentTo(target) && tileIsPresentAtSource && tileIsPresentAtTarget
    }

    func textOfTile(at position: PUZTilePosition) -> String? {
        precondition(boardContains(position))

        return tiles[position]?.text
    }

    mutating func moveTile(at source: PUZTilePosition, to target: PUZTilePosition) {
        guard let tileIsMovable = canMoveTile(at: source, to: target) else {
            fatalError("Move operation exceeds the bounds of the board")
        }

        precondition(tileIsMovable, "Tile cannot be moved to desired position")

        tiles[target] = tiles[source]
        tiles[source] = nil
    }
}

extension Array where Element == Array<PUZTile?> {
    subscript(_ position: PUZTilePosition) -> PUZTile? {
        get {
            return self[position.row][position.column]
        }

        set {
            self[position.row][position.column] = newValue
        }
    }
}

