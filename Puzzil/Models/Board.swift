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

    // MARK: - Board Properties

    let rowCount: Int
    let columnCount: Int
    private var tiles = [Tile?]()
    private var reservedPositions = [TilePosition: TileMoveOperation]()
    private let emptyPositions: Int

    // MARK: - Board Status

    var isSolved: Bool {
        for position in indices {
            if self[position].flatMap({ !$0.targets.contains(position) }) ?? false {
                return false
            }
        }

        return true
    }

    var progress: Double {
        return 1 - Double(distanceLeft) / Double(maxDistanceRemaining)
    }

    private var distanceLeft: Int {
        return indices.compactMap { position in
            self[position].flatMap({ $0.targets.map(position.distance).min()! })
        }.reduce(0, +)
    }

    private var maxDistanceRemaining: Int!

    // MARK: - Constructors

    init(matrix: [[BoardElement]]) {
        guard matrix.count > 0 else { fatalError("Matrix must have at least one row") }
        guard matrix.first!.count > 0 else { fatalError("Matrix must have at least one column") }

        rowCount = matrix.count
        columnCount = matrix.first!.count

        tiles.reserveCapacity(rowCount)

        var tilePositions = [String: [TilePosition]]()
        var tileTexts = [[String?]]()
        var emptyPositions = 0

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
                } else {
                    emptyPositions += 1
                }

                tileRow.append(text)
            }

            tileTexts.append(tileRow)
        }

        self.emptyPositions = emptyPositions

        tiles = tileTexts.flatMap { $0.map {
            guard let text = $0 else { return nil }

            let positions = tilePositions[text]!
            return Tile(targets: positions, text: text)
        } }

        maxDistanceRemaining = calculateMaxDistance()
    }

    // MARK: - Private Methods

    private func calculateMaxDistance() -> Int {
        return indices.compactMap { position in
            self[position].flatMap({ _ in
                let oppositePosition = TilePosition(
                    row: rowCount - 1 - position.row,
                    column: columnCount - 1 - position.column
                )

                return position.distance(to: oppositePosition)
            })
        }.reduce(0, +)
    }

    private func boardContains(_ position: TilePosition) -> Bool {
        return position.row >= 0 && position.row < rowCount &&
            position.column >= 0 && position.column < columnCount
    }

    private func tileIsPresent(at position: TilePosition) -> Bool {
        guard boardContains(position) else { return false }

        return self[position] != nil
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

        return self[position]?.text
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
                self[operation.targetPosition] = self[operation.startPosition]
                self[operation.startPosition] = nil
            }
        case .notPossible:
            fatalError("Cannot perform an impossible move operation")
        }
    }

    mutating func shuffle() {
        tiles.shuffle()

        if emptyPositions == 1 {
            while countTotalInversions() % 2 == 1 {
                tiles.shuffle()
            }
        }
    }

    func countInversions(at position: TilePosition) -> Int {
        var inversions = 0

        if let target = self[position]?.targets.first {
            self[index(after: position)...].forEach { tile in
                if let currentTarget = tile?.targets.first, currentTarget < target {
                    inversions += 1
                }
            }
        }

        return inversions
    }

    func countTotalInversions() -> Int {
        return indices.map(countInversions).reduce(0, +)
    }

    func clearingAllTiles() -> Board {
        return Board(matrix: Array(repeating: Array(repeating: nil, count: columnCount), count: rowCount))
    }
}

extension Board: BidirectionalCollection {
    var startIndex: TilePosition {
        return TilePosition(row: 0, column: 0)
    }

    var endIndex: TilePosition {
        return TilePosition(row: rowCount, column: 0)
    }

    func index(after position: TilePosition) -> TilePosition {
        let index = calculateIndex(for: position)
        return calculatePosition(for: index + 1)
    }

    func index(before position: TilePosition) -> TilePosition {
        let index = calculateIndex(for: position)
        return calculatePosition(for: index - 1)
    }

    private(set) subscript(_ position: TilePosition) -> Tile? {
        get {
            return tiles[calculateIndex(for: position)]
        }

        set {
            tiles[calculateIndex(for: position)] = newValue
        }
    }

    private func calculateIndex(for position: TilePosition) -> Int {
        return position.row * columnCount + position.column
    }

    private func calculatePosition(for index: Int) -> TilePosition {
        return TilePosition(
            row: index / columnCount,
            column: index % columnCount
        )
    }
}

enum TileMoveResult {
    case possible(after: [TileMoveOperation])
    case notPossible
}

extension Board: CustomStringConvertible {
    var description: String {
        var string = ""

        for (index, elementOrNil) in tiles.enumerated() {
            let rowIndex = index / columnCount
            let columnIndex = index % columnCount

            if columnIndex == 0 {
                string += Array(repeating: "-", count: columnCount * 4 + 1).joined()
                string += "\n"
            }

            if let element = elementOrNil {
                string += "| \(element) "
            } else if reservationExists(at: TilePosition(row: rowIndex, column: columnIndex)) {
                string += "| X "
            } else {
                string += "|   "
            }

            if columnIndex == columnCount - 1 {
                string += "|\n"
            }
        }

        string += Array(repeating: "-", count: columnCount * 4 + 1).joined()

        return string
    }
}
