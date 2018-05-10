//
//  BoardScrambler.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-08.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct BoardScrambler {
    static func scramble(_ board: Board, untilProgressIsBelow targetProgress: Double) throws -> Board {
        var minimumProgress = 1.0
        var stagnantRounds = 0
        var scrambledBoard = board

        while scrambledBoard.progress > targetProgress && stagnantRounds < 1000 {
            scrambledBoard = moveRandomTile(in: scrambledBoard)

            let progress = scrambledBoard.progress
            if progress < minimumProgress {
                minimumProgress = progress
                stagnantRounds = 0
            } else { stagnantRounds += 1 }
        }

        if scrambledBoard.progress > targetProgress { throw BoardScramblerError.scrambleStagnated }

        return scrambledBoard
    }

    private static func moveRandomTile(in board: Board) -> Board {
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

        var movedBoard = board
        movedBoard.perform(moveOperation)
        return movedBoard
    }

    private static func possibleMoveOperations(in board: Board) -> [TileMoveOperation] {
        return TilePosition.traversePositions(rows: board.rowCount, columns: board.columnCount).flatMap { position in
            [.left, .right, .up, .down]
                .map { direction in TileMoveOperation(moving: direction, from: position) }
                .filter { moveOperation in
                    guard case let .possible(after: operations) = board.canPerform(moveOperation),
                        operations == []
                    else { return false }

                    return true
                }
        }
    }

    private static func progressReduction(in board: Board, after moveOperation: TileMoveOperation) -> Double {
        var potentialBoard = board
        potentialBoard.perform(moveOperation)
        return board.progress - potentialBoard.progress
    }
}

enum BoardScramblerError: Error {
    case scrambleStagnated
}
