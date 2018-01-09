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
        var stagnantRounds = 0

        while board.progress > targetProgress && stagnantRounds < 1000 {
            moveRandomTile(in: &board)

            let progress = board.progress
            if progress < minimumProgress {
                stagnantRounds = 0
                minimumProgress = progress
            } else {
                stagnantRounds += 1
            }
        }
    }

    static func moveRandomTile(in board: inout Board) {
        let moves = possibleMoves(in: board)
        var maximumProgressReduction = -Double.greatestFiniteMagnitude
        for move in moves {
            maximumProgressReduction = max(maximumProgressReduction, progressReduction(in: board, with: move))
        }

        let effectiveMoves = moves.filter { move in
            return progressReduction(in: board, with: move) == maximumProgressReduction
        }

        let index = Int(arc4random_uniform(UInt32(effectiveMoves.count)))
        let move = effectiveMoves[index]

        board.moveTile(at: move.position, move.direction)
    }

    static func possibleMoves(in board: Board) -> [TileMove] {
        return TilePosition.traversePositions(rows: board.rows, columns: board.columns).flatMap { position in
            return possibleMoves(in: board, from: position)
        }
    }

    static func possibleMoves(in board: Board, from position: TilePosition) -> [TileMove] {
        return [
            TileMoveDirection.left,
            TileMoveDirection.right,
            TileMoveDirection.up,
            TileMoveDirection.down,
        ].filter { board.canMoveTile(at: position, $0) ?? false }
            .map { TileMove(position: position, direction: $0) }
    }

    static func progressReduction(in board: Board, with move: TileMove) -> Double {
        var potentialBoard = board
        potentialBoard.moveTile(at: move.position, move.direction)
        return board.progress - potentialBoard.progress
    }
}

