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
        for position in TilePosition.traversePositions(rows: rows, columns: columns) {
            if let tile = tiles[position], tile.target != position {
                return false
            }
        }

        return true
    }

    private var distanceLeft: Int {
        var distance = 0

        for position in TilePosition.traversePositions(rows: rows, columns: columns) {
            if let tile = tiles[position], tile.target != position {
                distance += position.distance(to: tile.target)
            }
        }

        return distance
    }

    private var maxDistanceLeft: Int {
        return (rows + columns - 2) * rows * columns
    }

    var progress: Double {
        return 1 - Double(distanceLeft) / Double(maxDistanceLeft)
    }

    init(from matrix: [[CustomStringConvertible?]]) {
        precondition(matrix.count > 0, "Matrix must have at least one row")
        precondition(matrix.first!.count > 0, "Matrix must have at least one column")

        rows = matrix.count
        columns = matrix.first!.count

        tiles.reserveCapacity(rows)

        for (rowIndex, row) in matrix.enumerated() {
            precondition(columns == row.count, "Provided matrix does not have a consistent row length")

            var tileRow = [Tile?]()
            tileRow.reserveCapacity(columns)

            for (columnIndex, element) in row.enumerated() {
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

    func canPerform(_ moveOperation: TileMoveOperation) -> Bool? {
        let target = moveOperation.targetPosition

        guard let tileIsPresentAtSource = tileIsPresent(at: moveOperation.position) else { return nil }

        guard let _ = tileIsPresent(at: target) else { return nil }

        if !tileIsPresentAtSource { return false }

        var currentPosition = target

        while (currentPosition != moveOperation.position) {
            if tileIsPresent(at: currentPosition)! { return false }

            currentPosition = target.moved(moveOperation.direction.opposite)
        }

        return true
    }

    func tileText(at position: TilePosition) -> String? {
        precondition(boardContains(position))

        return tiles[position]?.text
    }

    mutating func perform(_ moveOperation: TileMoveOperation) {
        guard let tileIsMovable = canPerform(moveOperation) else {
            fatalError("Move operation exceeds the bounds of the board")
        }

        precondition(tileIsMovable, "Tile cannot be moved to desired position")

        let targetPosition = moveOperation.targetPosition

        tiles[targetPosition] = tiles[moveOperation.position]
        tiles[moveOperation.position] = nil
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

