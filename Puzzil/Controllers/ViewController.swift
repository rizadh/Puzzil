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
        [6, 8, nil],
    ]

    static let telephoneBoard = [
        [7, 8, 9],
        [4, 5, 6],
        [1, 2, 3],
        [nil, 0, nil],
    ]

    static let textBoard = [
        ["One", "Two", "Three"],
        ["Four", "Five", "Six"],
        ["Seven", "Eight", "Nine"],
    ]

    var board = Board(from: ViewController.textBoard)

    override func viewDidLoad() {
        super.viewDidLoad()

        view = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)

        let boardView = BoardView()
        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self

        let button1 = RoundedButton()
        button1.text = "Back"
        let button2 = RoundedButton()
        button2.text = "Solve"
        let button3 = RoundedButton()
        button3.text = "Reset"

        let buttons = UIStackView(arrangedSubviews: [button1, button2, button3,])
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

    func boardView(_ boardView: BoardView, canMoveTileAt source: TilePosition, to target: TilePosition) -> Bool? {
        return board.canMoveTile(at: source, to: target)
    }

    func boardView(_ boardView: BoardView, tileWasMovedFrom source: TilePosition, to target: TilePosition) {
        board.moveTile(at: source, to: target)
    }
}
