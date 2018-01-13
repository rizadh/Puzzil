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
    static let difficulty = 0.5

    override var prefersStatusBarHidden: Bool {
        return true
    }

    var board: Board!
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

        let stats = UIStackView(arrangedSubviews: [moveStat, timeStat])
        stats.translatesAutoresizingMaskIntoConstraints = false
        stats.distribution = .fillEqually

        let statsLayoutGuide = UILayoutGuide()

        let restartButton = RoundedButton() { [unowned self] _ in
            self.resetBoard()
        }
        restartButton.text = "Restart"

        let buttons = UIStackView(arrangedSubviews: [restartButton])
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.distribution = .fillEqually
        buttons.spacing = 8

        view.addSubview(stats)
        view.addSubview(boardView)
        view.addSubview(buttons)

        view.addLayoutGuide(statsLayoutGuide)

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
            boardView.widthAnchor.constraint(equalTo: safeArea.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: safeArea.heightAnchor),
            buttons.heightAnchor.constraint(equalToConstant: 60),
        ]

        optionalConstraints.forEach { $0.priority = .defaultHigh }

        NSLayoutConstraint.activate(optionalConstraints + [
            statsLayoutGuide.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            statsLayoutGuide.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            statsLayoutGuide.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            statsLayoutGuide.bottomAnchor.constraint(equalTo: boardView.topAnchor, constant: -16),

            stats.centerXAnchor.constraint(equalTo: statsLayoutGuide.centerXAnchor),
            stats.centerYAnchor.constraint(equalTo: statsLayoutGuide.centerYAnchor),
            stats.widthAnchor.constraint(equalTo: statsLayoutGuide.widthAnchor),

            boardView.leftAnchor.constraint(greaterThanOrEqualTo: safeArea.leftAnchor, constant: 16),
            boardView.rightAnchor.constraint(lessThanOrEqualTo: safeArea.rightAnchor, constant: -16),
            boardView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            boardView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),

            buttons.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            buttons.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            buttons.topAnchor.constraint(greaterThanOrEqualTo: boardView.bottomAnchor, constant: 16),
            buttons.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
            buttons.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
        ])
    }

    private func resetBoard() {
        board = .regularBoard
        BoardScrambler.scramble(&board!, untilProgressIsBelow: 1 - ViewController.difficulty)
        timeStatRefresher?.isPaused = false

        boardView.reloadTiles()

        moves = 0
        updateMoveStat()
        startTime = Date()
    }

    private func updateMoveStat() {
        moveStat.value = moves.description
    }

    @objc private func updateTimeStat() {
        let time = Int(elapsedTime)
        let minutes = time / 60
        let seconds = time % 60

        if minutes > 0 {
            timeStat.value = "\(minutes)m \(seconds)s"
        } else {
            timeStat.value = "\(seconds)s"
        }
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
