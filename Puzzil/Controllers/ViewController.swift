//
//  ViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import SpriteKit
import CoreMotion

class ViewController: UIViewController, BoardViewDelegate {
    static let regularBoard = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, nil],
    ]

    static let telephoneBoard = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
        [nil, 0, nil],
    ]

    static let difficulty = 0.5

    var board: Board!
    let boardView = BoardView()
    var startTime: Date!
    var moves = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        view = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self
        resetBoard()

        let restartButton = RoundedButton() { [unowned self] _ in
            self.resetBoard()
        }
        restartButton.text = "Restart"

        let buttons = UIStackView(arrangedSubviews: [restartButton])
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.distribution = .fillEqually
        buttons.spacing = 8

        let boardLayoutGuide = UILayoutGuide()

        let optionalConstraints = [
            boardView.widthAnchor.constraint(equalTo: boardLayoutGuide.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: boardLayoutGuide.heightAnchor),
        ]

        optionalConstraints.forEach { $0.priority = .defaultHigh }

        view.addSubview(boardView)
        view.addSubview(buttons)
        view.addLayoutGuide(boardLayoutGuide)

        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate(optionalConstraints + [
            boardLayoutGuide.leftAnchor.constraint(equalTo: buttons.leftAnchor),
            boardLayoutGuide.rightAnchor.constraint(equalTo: buttons.rightAnchor),
            boardLayoutGuide.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),

            boardView.widthAnchor.constraint(lessThanOrEqualTo: boardLayoutGuide.widthAnchor),
            boardView.heightAnchor.constraint(lessThanOrEqualTo: boardLayoutGuide.heightAnchor),
            boardView.centerXAnchor.constraint(equalTo: boardLayoutGuide.centerXAnchor),
            boardView.centerYAnchor.constraint(equalTo: boardLayoutGuide.centerYAnchor),

            buttons.heightAnchor.constraint(equalToConstant: 48),

            buttons.leftAnchor.constraintEqualToSystemSpacingAfter(safeArea.leftAnchor, multiplier: 2),
            safeArea.rightAnchor.constraintEqualToSystemSpacingAfter(buttons.rightAnchor, multiplier: 2),
            buttons.topAnchor.constraintEqualToSystemSpacingBelow(boardLayoutGuide.bottomAnchor, multiplier: 2),
            safeArea.bottomAnchor.constraintEqualToSystemSpacingBelow(buttons.bottomAnchor, multiplier: 2),
        ])
    }

    func resetBoard() {
        board = Board(from: ViewController.telephoneBoard)
        BoardScrambler.scramble(&board!, untilProgressIsBelow: 1 - ViewController.difficulty)

        boardView.reloadTiles()

        moves = 0
        startTime = Date()
    }

    func numberOfRows(in boardView: BoardView) -> Int {
        return board.rows
    }

    func numberOfColumns(in boardView: BoardView) -> Int {
        return board.columns
    }

    func boardView(_ boardView: BoardView, tileTextAt position: TilePosition) -> String? {
        return board.tileText(at: position)
    }

    func boardView(_ boardView: BoardView, canPerform moveOperation: TileMoveOperation) -> Bool? {
        return board.canPerform(moveOperation)
    }

    func boardView(_ boardView: BoardView, didPerform moveOperation: TileMoveOperation) {
        board.perform(moveOperation)
        moves += 1

        if board.isSolved {
            let endTime = Date()
            let elapsedTime = endTime.timeIntervalSince(startTime)
            let roundedTime = (elapsedTime * 1e2).rounded() / 1e2

            let title = "Solved in \(moves) moves and \(roundedTime) seconds!"
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { [unowned self] _ in
                self.resetBoard()
            }))

            present(alert, animated: true, completion: nil)
        }
    }
}
