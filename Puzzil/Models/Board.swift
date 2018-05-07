//
//  Board.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-23.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import Foundation

struct Board {
    private typealias TileMatrix = [[Tile?]]

    // MARK: - Board Properties

    let rows: Int
    let columns: Int
    private var tiles: TileMatrix = []

    // MARK: - Board Status

    var isSolved: Bool {
        for position in TilePosition.traversePositions(rows: rows, columns: columns) {
            if let tile = tiles[position], !tile.targets.contains(position) {
                return false
            }
        }

        return true
    }

    var progress: Double {
        return 1 - Double(distanceLeft) / Double(maxDistanceRemaining)
    }

    private var distanceLeft: Int {
        var distance = 0

        for position in TilePosition.traversePositions(rows: rows, columns: columns) {
            if let tile = tiles[position], !tile.targets.contains(position) {
                distance += tile.targets.map(position.distance(to:)).min()!
            }
        }

        return distance
    }

    private let maxDistanceRemaining: Int

    private static func calculateMaxDistance(for tiles: TileMatrix, rows: Int, columns: Int) -> Int {
        var maxDistance = 0

        let topLeftCorner = TilePosition(row: 0, column: 0)
        let topRightCorner = TilePosition(row: 0, column: columns - 1)
        let bottomRightCorner = TilePosition(row: rows - 1, column: columns - 1)
        let bottomLeftCorner = TilePosition(row: rows - 1, column: 0)

        for position in TilePosition.traversePositions(rows: rows, columns: columns) {
            if tiles[position] != nil {
                maxDistance += max(
                    position.distance(to: topLeftCorner),
                    position.distance(to: topRightCorner),
                    position.distance(to: bottomRightCorner),
                    position.distance(to: bottomLeftCorner)
                )
            }
        }

        return maxDistance
    }

    // MARK: - Constructors

    init(from matrix: [[CustomStringConvertible?]]) {
        guard matrix.count > 0 else { fatalError("Matrix must have at least one row") }
        guard matrix.first!.count > 0 else { fatalError("Matrix must have at least one column") }

        rows = matrix.count
        columns = matrix.first!.count

        tiles.reserveCapacity(rows)

        var tilePositions = [String: [TilePosition]]()
        var tileTexts = [[String?]]()

        for (rowIndex, row) in matrix.enumerated() {
            guard columns == row.count else { fatalError("Provided matrix does not have a consistent row length") }

            var tileRow = [String?]()
            tileRow.reserveCapacity(columns)

            for (columnIndex, element) in row.enumerated() {
                var text: String?

                if let element = element {
                    text = element.description
                    let position = TilePosition(row: rowIndex, column: columnIndex)

                    let previousPositions = tilePositions[text!] ?? []
                    let updatedPositions = previousPositions + [position]
                    tilePositions[text!] = updatedPositions
                }

                tileRow.append(text)
            }

            tileTexts.append(tileRow)
        }

        tiles = tileTexts.map { $0.map {
            guard let text = $0 else { return nil }

            let positions = tilePositions[text]!
            return Tile(targets: positions, text: text)
        } }

        maxDistanceRemaining = Board.calculateMaxDistance(for: tiles, rows: rows, columns: columns)
    }

    // MARK: - Private Methods

    private func boardContains(_ position: TilePosition) -> Bool {
        return position.row >= 0 && position.row < rows &&
            position.column >= 0 && position.column < columns
    }

    private func tileIsPresent(at position: TilePosition) -> Bool? {
        guard boardContains(position) else { return nil }

        return tiles[position] != nil
    }

    // MARK: - Public Methods

    func canPerform(_ moveOperation: TileMoveOperation) -> Bool? {
        let target = moveOperation.targetPosition

        guard let tileIsPresentAtSource = tileIsPresent(at: moveOperation.position) else { return nil }

        guard let _ = tileIsPresent(at: target) else { return nil }

        if !tileIsPresentAtSource { return false }

        var currentPosition = target

        while currentPosition != moveOperation.position {
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

// Facilitate retrieving tiles from a TileMatrix
extension Array where Element == [Tile?] {
    subscript(_ position: TilePosition) -> Tile? {
        get {
            return self[position.row][position.column]
        }

        set {
            self[position.row][position.column] = newValue
        }
    }
}
