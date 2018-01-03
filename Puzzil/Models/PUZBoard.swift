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
    var tiles = [[PUZTile?]]()

    init(from matrix: [[String?]]) {
        precondition(matrix.count > 0, "Matrix must have at least one row")
        precondition(matrix.first!.count > 0, "Matrix must have at least one column")

        columns = matrix.count
        rows = matrix.first!.count

        matrix.enumerated().forEach { (columnIndex, row) in
            precondition(columns == row.count, "Provided matrix does not have a consistent row length")

            tiles.append([])

            row.enumerated().forEach { (rowIndex, element) in
                if let element = element {
                    tiles[columnIndex][rowIndex] = PUZTile(targetRow: rowIndex, targetColumn: columnIndex, text: element)
                } else {
                    tiles[columnIndex][rowIndex] = nil
                }
            }
        }
    }

    func boardContains(_ position: PUZTilePosition) -> Bool {
        return position.row < rows && position.column < columns
    }

    func tileIsPresent(at position: PUZTilePosition) -> Bool {
        guard boardContains(position) else {
            fatalError("Attempted to access a position not contained by the board")
        }

        return tiles[position.row][position.column] != nil
    }

    func canMoveTile(at source: PUZTilePosition, to target: PUZTilePosition) -> Bool {
        return source.isAdjacentTo(target) &&
            boardContains(source) &&
            boardContains(target) &&
            tileIsPresent(at: source) &&
            !tileIsPresent(at: target)
    }

    func moveTile(at source: PUZTilePosition, to target: PUZTilePosition) {
        precondition(canMoveTile(at: source, to: target))
    }
}

