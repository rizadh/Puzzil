//
//  BoardScrambler.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-08.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct BoardScrambler {
    static func scramble(_ board: inout Board, untilProgressIsBelow targetProgress: Double) {
        var minimumProgress = 1.0

        while board.progress > targetProgress {
            moveRandomTile(in: &board)

            let progress = board.progress
            if progress < minimumProgress {
                minimumProgress = progress
            }
        }
    }

    private static func moveRandomTile(in board: inout Board) {
        let moveOperations = possibleMoveOperations(in: board)
        var maximumProgressReduction = -Double.greatestFiniteMagnitude
        for moveOperation in moveOperations {
            maximumProgressReduction = max(maximumProgressReduction, progressReduction(in: board, after: moveOperation))
        }

        let effectiveMoves = moveOperations.filter { moveOperation in
            return progressReduction(in: board, after: moveOperation) == maximumProgressReduction
        }

        let index = Int(arc4random_uniform(UInt32(effectiveMoves.count)))
        let moveOperation = effectiveMoves[index]

        board.perform(moveOperation)
    }

    private static func possibleMoveOperations(in board: Board) -> [TileMoveOperation] {
        return TilePosition.traversePositions(rows: board.rows, columns: board.columns).flatMap { position in
            [.left, .right, . up, .down]
                .map { direction in TileMoveOperation(moving: direction, from: position) }
                .filter { moveOperation in board.canPerform(moveOperation) ?? false }
        }
    }

    private static func progressReduction(in board: Board, after moveOperation: TileMoveOperation) -> Double {
        var potentialBoard = board
        potentialBoard.perform(moveOperation)
        return board.progress - potentialBoard.progress
    }
}

