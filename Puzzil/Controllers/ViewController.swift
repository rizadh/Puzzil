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

    override var prefersStatusBarHidden: Bool {
        return true
    }

    var board = Board(from: [[nil]])
    let boardView = BoardView()
    var startTime = Date()
    let timeStat = StatView("Time")
    var timeStatRefresher: CADisplayLink!
    var moves = 0
    let moveStat = StatView("Moves")

    var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self

        resetBoard()
        setupSubviews()
    }

    private func setupSubviews() {
        timeStatRefresher = CADisplayLink(target: self, selector: #selector(updateTimeStat))
        timeStatRefresher.add(to: .main, forMode: .defaultRunLoopMode)

        moveStat.translatesAutoresizingMaskIntoConstraints = false
        timeStat.translatesAutoresizingMaskIntoConstraints = false

        let topBarGuide = UILayoutGuide()
        let boardGuide = UILayoutGuide()
        let bottomBarGuide = UILayoutGuide()

        let restartButton = RoundedButton() { [unowned self] _ in
            self.resetBoard()
        }
        restartButton.text = "Restart"

        let buttons = UIStackView(arrangedSubviews: [restartButton])
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.distribution = .fillEqually
        buttons.spacing = 8

        view.addSubview(moveStat)
        view.addSubview(timeStat)
        view.addSubview(boardView)
        view.addSubview(buttons)

        view.addLayoutGuide(topBarGuide)

        view.addLayoutGuide(boardGuide)
        view.addLayoutGuide(bottomBarGuide)

        let safeArea: UILayoutGuide

        if #available(iOS 11.0, *) {
            safeArea = view.safeAreaLayoutGuide
        } else {
            safeArea = UILayoutGuide()

            view.addLayoutGuide(safeArea)

            NSLayoutConstraint.activate([
                safeArea.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                safeArea.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                safeArea.leftAnchor.constraint(equalTo: view.leftAnchor),
                safeArea.rightAnchor.constraint(equalTo: view.rightAnchor),
            ])
        }

        let optionalConstraints = [
            boardView.widthAnchor.constraint(equalTo: boardGuide.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: boardGuide.heightAnchor),
        ]

        optionalConstraints.forEach { $0.priority = .defaultHigh }

        let buttonHeightConstraint = buttons.heightAnchor.constraint(equalToConstant: 48)
        buttonHeightConstraint.priority = UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1)
        buttonHeightConstraint.isActive = true

        NSLayoutConstraint.activate(optionalConstraints + [
            topBarGuide.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            topBarGuide.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            topBarGuide.bottomAnchor.constraint(equalTo: boardView.topAnchor),

            boardGuide.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            boardGuide.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            boardGuide.widthAnchor.constraint(equalTo: safeArea.widthAnchor, constant: -32),

            bottomBarGuide.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            bottomBarGuide.topAnchor.constraint(equalTo: boardView.bottomAnchor),
            bottomBarGuide.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),

            topBarGuide.widthAnchor.constraint(equalTo: boardView.widthAnchor),
            bottomBarGuide.widthAnchor.constraint(equalTo: boardView.widthAnchor),
            topBarGuide.heightAnchor.constraint(equalTo: bottomBarGuide.heightAnchor),

            moveStat.leftAnchor.constraint(equalTo: topBarGuide.leftAnchor),
            moveStat.rightAnchor.constraint(equalTo: topBarGuide.centerXAnchor),
            moveStat.centerYAnchor.constraint(equalTo: topBarGuide.centerYAnchor),

            timeStat.leftAnchor.constraint(equalTo: topBarGuide.centerXAnchor),
            timeStat.rightAnchor.constraint(equalTo: topBarGuide.rightAnchor),
            timeStat.centerYAnchor.constraint(equalTo: topBarGuide.centerYAnchor),

            boardView.widthAnchor.constraint(lessThanOrEqualTo: boardGuide.widthAnchor),
            boardView.heightAnchor.constraint(lessThanOrEqualTo: boardGuide.heightAnchor),
            boardView.centerXAnchor.constraint(equalTo: boardGuide.centerXAnchor),
            boardView.centerYAnchor.constraint(equalTo: boardGuide.centerYAnchor),

            buttons.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            buttons.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            buttons.centerYAnchor.constraint(equalTo: bottomBarGuide.centerYAnchor),
            buttons.topAnchor.constraint(greaterThanOrEqualTo: boardView.bottomAnchor, constant: 16),
            buttons.heightAnchor.constraint(lessThanOrEqualTo: boardView.heightAnchor, multiplier: 0.2)
        ])
    }

    private func resetBoard() {
        board = Board(from: ViewController.regularBoard)
        BoardScrambler.scramble(&board, untilProgressIsBelow: 1 - ViewController.difficulty)
        timeStatRefresher?.isPaused = false

        boardView.reloadTiles()

        moves = 0
        updateMoveStat()
        startTime = Date()
        updateTimeStat()
    }

    private func updateMoveStat() {
        moveStat.value = moves.description
    }

    @objc private func updateTimeStat() {
        timeStat.value = "\(Int(elapsedTime)) s"
    }

    private func boardWasSolved() {
        timeStatRefresher.isPaused = true

        let title = "Solved in \(moves) moves and \((elapsedTime * 100).rounded() / 100) seconds!"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { [unowned self] _ in
            self.resetBoard()
        }))

        present(alert, animated: true, completion: nil)
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
        updateMoveStat()

        if board.isSolved { boardWasSolved() }
    }
}
