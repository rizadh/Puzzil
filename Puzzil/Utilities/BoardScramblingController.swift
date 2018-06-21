//
//  BoardScramblingController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-08.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

class BoardScramblingController {
    private var boardGenerators: [BoardStyle: QueuedGenerator<Board>]

    init() {
        boardGenerators = Dictionary(uniqueKeysWithValues: BoardStyle.all.map { boardStyle in
            let generator = QueuedGenerator(name: boardStyle.rawValue, queueLength: 2) {
                return BoardScramblingController.generateBoard(style: boardStyle)
            }

            return (boardStyle, generator)
        })
    }

    func nextBoard(style: BoardStyle) -> Board {
        return boardGenerators[style]!.next()
    }

    func waitForBoard(style: BoardStyle) {
        boardGenerators[style]!.wait()
    }

    private static func generateBoard(style: BoardStyle) -> Board? {
        var board = style.board
        let targetProgress = style.targetScrambleProgress
        var minimumProgress = 1.0
        let maxRounds = 3
        var rounds = 0

        while board.progress > targetProgress {
            moveRandomTile(in: &board)

            let progress = board.progress
            if progress < minimumProgress {
                minimumProgress = progress
                rounds = 0
            } else if rounds < maxRounds {
                rounds += 1
            } else { return nil }
        }

        return board
    }

    private static func moveRandomTile(in board: inout Board) {
        let moveOperations = possibleMoveOperations(for: board)
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

    private static func possibleMoveOperations(for board: Board) -> [TileMoveOperation] {
        return board.indices.flatMap { position in
            [.left, .right, .up, .down]
                .map { direction in TileMoveOperation(position: position, direction: direction) }
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
