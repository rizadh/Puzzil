//
//  BoardViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardViewController: UIViewController, BoardViewDelegate {
    override var prefersStatusBarHidden: Bool {
        return true
    }

    private var originalBoard: Board
    private var board: Board
    private let difficulty: Double

    private let boardView = BoardView()
    private let timeStat = StatView("Time")
    private let moveStat = StatView("Moves")

    private var timeStatRefresher: CADisplayLink!

    private var startTime = Date()
    private var moves = 0

    private var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }

    init(board: Board, difficulty: Double) {
        originalBoard = board
        self.board = board
        self.difficulty = difficulty

        super.init(nibName: nil, bundle: nil)

        modalTransitionStyle = .flipHorizontal
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let gradientView = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)
        gradientView.frame = view.bounds
        gradientView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(gradientView)

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

        let backButton = RoundedButton() { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }
        backButton.text = "Back"
        let restartButton = RoundedButton() { [unowned self] _ in
            self.resetBoard()
        }
        restartButton.text = "Restart"

        let buttons = UIStackView(arrangedSubviews: [backButton, restartButton])
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.distribution = .fillEqually
        buttons.spacing = 8

        view.addSubview(stats)
        view.addSubview(boardView)
        view.addSubview(buttons)

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

        [
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor),
            buttons.heightAnchor.constraint(equalToConstant: 60),
        ].forEach {
            $0.priority = .defaultHigh
            $0.isActive = true
        }

        if #available(iOS 10.0, *) {
            let topMargin = safeArea.topAnchor.anchorWithOffset(to: stats.topAnchor)
            let bottomMargin = stats.bottomAnchor.anchorWithOffset(to: boardView.topAnchor)

            NSLayoutConstraint.activate([
                topMargin.constraint(equalTo: bottomMargin),
                topMargin.constraint(greaterThanOrEqualToConstant: 16),
                bottomMargin.constraint(greaterThanOrEqualToConstant: 16),
            ])
        } else {
            NSLayoutConstraint.activate([
                stats.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: 16),
                stats.bottomAnchor.constraint(lessThanOrEqualTo: boardView.topAnchor, constant: -16),
            ])
        }

        NSLayoutConstraint.activate([
            stats.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            stats.rightAnchor.constraint(equalTo: boardView.rightAnchor),

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
        board = originalBoard
        BoardScrambler.scramble(&board, untilProgressIsBelow: 1 - difficulty)
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
