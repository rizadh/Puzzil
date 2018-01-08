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
        [7, 8, 9],
        [4, 5, 6],
        [1, 2, 3],
        [nil, 0, nil],
    ]

    static let tenByTenBoard = [
        [00, 01, 02, 03, 04, 05, 06, 07, 08, 09],
        [10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
        [20, 21, 22, 23, 24, 25, 26, 27, 28, 29],
        [30, 31, 32, 33, 34, 35, 36, 37, 38, 39],
        [40, 41, 42, 43, 44, 45, 46, 47, 48, 49],
        [50, 51, 52, 53, 54, 55, 56, 57, 58, 59],
        [60, 61, 62, 63, 64, 65, 66, 67, 68, 69],
        [70, 71, 72, 73, 74, 75, 76, 77, 78, 79],
        [80, 81, 82, 83, 84, 85, 86, 87, 88, 89],
        [90, 91, 92, 93, 94, 95, 96, 97, 98, nil],
    ]

    var board = Board(from: ViewController.telephoneBoard)

    override func viewDidLoad() {
        super.viewDidLoad()

        view = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)

        let boardView = BoardView()
        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self

        let backButton = RoundedButton()
        backButton.text = "Back"
        let resetButton = RoundedButton()
        resetButton.text = "Reset"

        let buttons = UIStackView(arrangedSubviews: [backButton, resetButton])
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

    func numberOfRows(in boardView: BoardView) -> Int {
        return board.rows
    }

    func numberOfColumns(in boardView: BoardView) -> Int {
        return board.columns
    }

    func boardView(_ boardView: BoardView, textForTileAt position: TilePosition) -> String? {
        return board.textOfTile(at: position)
    }

    func boardView(_ boardView: BoardView, canMoveTileAt position: TilePosition, _ direction: TileMoveDirection) -> Bool? {
        return board.canMoveTile(at: position, direction)
    }

    func boardView(_ boardView: BoardView, tileWasMoved direction: TileMoveDirection, from position: TilePosition) {
        board.moveTile(at: position, direction)
    }
}
