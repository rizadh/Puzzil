//
//  Board.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-23.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import Foundation

typealias BoardElement = CustomStringConvertible?

struct Board {
    private typealias TileMatrix = [[Tile?]]

    // MARK: - Board Properties

    let rowCount: Int
    let columnCount: Int
    private var tiles: TileMatrix = []
    private var reservedPositions = [TilePosition: TileMoveOperation]()

    // MARK: - Board Status

    var isSolved: Bool {
        for position in TilePosition.traversePositions(rows: rowCount, columns: columnCount) {
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

        for position in TilePosition.traversePositions(rows: rowCount, columns: columnCount) {
            if let tile = tiles[position], !tile.targets.contains(position) {
                distance += tile.targets.map(position.distance(to:)).min()!
            }
        }

        return distance
    }

    private let maxDistanceRemaining: Int

    private static func calculateMaxDistance(for tiles: TileMatrix, rows: Int, columns: Int) -> Int {
        var maxDistance = 0

        for position in TilePosition.traversePositions(rows: rows, columns: columns) {
            if tiles[position] != nil {
                let oppositePosition = TilePosition(row: rows - 1 - position.row, column: columns - 1 - position.column)
                maxDistance += position.distance(to: oppositePosition)
            }
        }

        return maxDistance
    }

    // MARK: - Constructors

    init(matrix: [[BoardElement]]) {
        guard matrix.count > 0 else { fatalError("Matrix must have at least one row") }
        guard matrix.first!.count > 0 else { fatalError("Matrix must have at least one column") }

        rowCount = matrix.count
        columnCount = matrix.first!.count

        tiles.reserveCapacity(rowCount)

        var tilePositions = [String: [TilePosition]]()
        var tileTexts = [[String?]]()

        for (rowIndex, row) in matrix.enumerated() {
            guard columnCount == row.count else { fatalError("Provided matrix does not have a consistent row length") }

            var tileRow = [String?]()
            tileRow.reserveCapacity(columnCount)

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

        maxDistanceRemaining = Board.calculateMaxDistance(for: tiles, rows: rowCount, columns: columnCount)
    }

    // MARK: - Private Methods

    private func boardContains(_ position: TilePosition) -> Bool {
        return position.row >= 0 && position.row < rowCount &&
            position.column >= 0 && position.column < columnCount
    }

    private func tileIsPresent(at position: TilePosition) -> Bool {
        guard boardContains(position) else { return false }

        return tiles[position] != nil
    }

    private func reservationExists(at position: TilePosition) -> Bool {
        return reservedPositions.keys.contains(position)
    }

    // MARK: - Public Methods

    func canPerform(_ moveOperation: TileMoveOperation) -> TileMoveResult {
        // Check that a tile is present to be moved
        guard tileIsPresent(at: moveOperation.startPosition),
            boardContains(moveOperation.targetPosition),
            !reservationExists(at: moveOperation.targetPosition)
        else { return .notPossible }

        // Check if the target position is already occupied
        if tileIsPresent(at: moveOperation.targetPosition) {
            // Check if the next tile can be moved away
            switch canPerform(moveOperation.nextOperation) {
            case let .possible(after: operations):
                return .possible(after: operations + [moveOperation.nextOperation])
            case .notPossible:
                return .notPossible
            }
        } else {
            return .possible(after: [])
        }
    }

    func tileText(at position: TilePosition) -> String? {
        precondition(boardContains(position))

        return tiles[position]?.text
    }

    mutating func begin(_ moveOperation: TileMoveOperation) {
        switch canPerform(moveOperation) {
        case let .possible(after: operations):
            for operation in operations + [moveOperation] {
                reservedPositions[operation.startPosition] = moveOperation
                reservedPositions[operation.targetPosition] = moveOperation
            }
        case .notPossible:
            fatalError("Cannot begin an impossible move operation")
        }
    }

    mutating func cancel(_ moveOperation: TileMoveOperation) {
        guard reservedPositions.contains(where: { _, keyMoveOperation in moveOperation == keyMoveOperation }) else {
            fatalError("Cannot cancel a move that was not started")
        }

        reservedPositions = reservedPositions.filter { _, keyMoveOperation in moveOperation != keyMoveOperation }
    }

    mutating func complete(_ moveOperation: TileMoveOperation) {
        cancel(moveOperation)
        perform(moveOperation)
    }

    mutating func perform(_ moveOperation: TileMoveOperation) {
        switch canPerform(moveOperation) {
        case let .possible(after: operations):
            for operation in operations + [moveOperation] {
                tiles[operation.targetPosition] = tiles[operation.startPosition]
                tiles[operation.startPosition] = nil
            }
        case .notPossible:
            fatalError("Cannot perform an impossible move operation")
        }
    }

    func clearingAllTiles() -> Board {
        return Board(matrix: Array(repeating: Array(repeating: nil, count: columnCount), count: rowCount))
    }
}

enum TileMoveResult {
    case possible(after: [TileMoveOperation])
    case notPossible
}

extension Board: CustomStringConvertible {
    var description: String {
        var string = ""

        for row in tiles {
            for _ in 0..<row.count * 4 + 1 {
                string += "-"
            }
            string += "\n"
            for elementOrNil in row {
                if let element = elementOrNil {
                    string += "| \(element) "
                } else {
                    string += "|   "
                }
            }
            string += "|\n"
        }

        for _ in 0..<tiles.first!.count * 4 + 1 {
            string += "-"
        }

        return string
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
