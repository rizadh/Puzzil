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

    static let difficulty = 0.4

    var board: Board!
    let boardView = BoardView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self
        scrambleBoard()

        let restartButton = RoundedButton() { [unowned self] _ in
            self.scrambleBoard()
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

    func scrambleBoard() {
        board = Board(from: ViewController.regularBoard)
        BoardScrambler.scramble(&board!, untilProgressIsBelow: 1 - ViewController.difficulty)
        boardView.reloadTiles()
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

        if board.isSolved {
            let alert = UIAlertController(title: "You solved it!", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Restart", style: .cancel, handler: { [unowned self] _ in
                self.scrambleBoard()
            }))

            present(alert, animated: true, completion: nil)
        }
    }
}
