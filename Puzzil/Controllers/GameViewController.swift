//
//  GameViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, BoardViewDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.themeBackground.isLight {
            return .default
        } else {
            return .lightContent
        }
    }

    private var boardConfiguration: BoardConfiguration
    private var board: Board!
    private let difficulty: Double
    private var operationsInProgress = Set<TileMoveOperation>()

    private let stats = UIStackView()
    private let bestTimeStat = StatView()
    private let timeStat = StatView()
    private let movesStat = StatView()
    private let boardView = BoardView()
    private let buttons = UIStackView()
    private var endButton: UIButton!
    private var restartButton: UIButton!

    private var timeStatRefresher: CADisplayLink!

    private var startTime = Date()
    private var moves = 0 {
        didSet {
            movesStat.valueLabel.text = moves.description
        }
    }

    private var elapsedSeconds: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }

    private var progressWasMade: Bool {
        return moves > 0
    }

    private let bestTimesController = (UIApplication.shared.delegate as! AppDelegate).bestTimesController

    private static func secondsToTimeString(_ rawSeconds: Double) -> String {
        return String(format: "%.1f s", rawSeconds)
    }

    init(boardConfiguration: BoardConfiguration, difficulty: Double) {
        self.boardConfiguration = boardConfiguration
        self.difficulty = difficulty

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .themeBackground

        board = boardFromConfiguration()

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self

        resetBoard()
        setupSubviews()
    }

    override func viewDidDisappear(_ animated: Bool) {
        timeStatRefresher.invalidate()
    }

    private func boardFromConfiguration() -> Board {
        return Board(from: boardConfiguration.matrix)
    }

    private func setupSubviews() {
        timeStatRefresher = CADisplayLink(target: self, selector: #selector(updateTimeStat))
        if #available(iOS 10.0, *) {
            timeStatRefresher.preferredFramesPerSecond = 10
        } else {
            timeStatRefresher.frameInterval = 60 / 10
        }
        timeStatRefresher.add(to: .main, forMode: .defaultRunLoopMode)

        let resetRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(displayResetBestTimePrompt))
        bestTimeStat.addGestureRecognizer(resetRecognizer)

        bestTimeStat.titleLabel.text = "Best Time"
        timeStat.titleLabel.text = "Time"
        movesStat.titleLabel.text = "Moves"

        stats.addArrangedSubview(bestTimeStat)
        stats.addArrangedSubview(timeStat)
        stats.addArrangedSubview(movesStat)
        stats.translatesAutoresizingMaskIntoConstraints = false
        stats.distribution = .fillEqually

        endButton = UIButton.createThemedButton()
        endButton.addTarget(self, action: #selector(endButtonWasTapped), for: .primaryActionTriggered)
        endButton.setTitle("End", for: .normal)

        restartButton = UIButton.createThemedButton()
        restartButton.addTarget(self, action: #selector(restartButtonWasTapped), for: .primaryActionTriggered)
        restartButton.setTitle("Restart", for: .normal)

        buttons.addArrangedSubview(endButton)
        buttons.addArrangedSubview(restartButton)
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.distribution = .fillEqually
        buttons.spacing = 8

        view.addSubview(stats)
        view.addSubview(boardView)
        view.addSubview(buttons)

        let safeArea: UILayoutGuide = {
            if #available(iOS 11.0, *) {
                return view.safeAreaLayoutGuide
            } else {
                let safeAreaLayoutGuide = UILayoutGuide()

                view.addLayoutGuide(safeAreaLayoutGuide)

                NSLayoutConstraint.activate([
                    safeAreaLayoutGuide.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                    safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                    safeAreaLayoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor),
                    safeAreaLayoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor),
                ])

                return safeAreaLayoutGuide
            }
        }()

        let statsLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(statsLayoutGuide)

        NSLayoutConstraint.activate([
            statsLayoutGuide.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            boardView.topAnchor.constraint(equalTo: statsLayoutGuide.bottomAnchor, constant: 16),

            stats.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            stats.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            stats.centerYAnchor.constraint(equalTo: statsLayoutGuide.centerYAnchor),

            boardView.leftAnchor.constraint(greaterThanOrEqualTo: safeArea.leftAnchor, constant: 16),
            boardView.rightAnchor.constraint(lessThanOrEqualTo: safeArea.rightAnchor, constant: -16),
            boardView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            boardView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),

            buttons.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            buttons.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            buttons.topAnchor.constraint(greaterThanOrEqualTo: boardView.bottomAnchor, constant: 16),
            buttons.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
            buttons.heightAnchor.constraint(equalToConstant: 48),
        ] + [
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor),
        ].map {
            $0.priority = .defaultHigh
            return $0
        })
    }

    private func resetBoard() {
        board = boardFromConfiguration()
        do { board = try BoardScrambler.scramble(board, untilProgressIsBelow: 1 - difficulty) }
        catch BoardScramblerError.scrambleStagnated { navigateToMainMenu() }
        catch { fatalError(error.localizedDescription) }
        timeStatRefresher?.isPaused = false

        boardView.reloadTiles()

        updateBestTimeStat()
        moves = 0
        startTime = Date()
    }

    private func updateBestTimeStat() {
        if let bestTime = bestTimesController.getBestTime(for: boardConfiguration.name) {
            bestTimeStat.valueLabel.text = GameViewController.secondsToTimeString(bestTime)
        } else {
            bestTimeStat.valueLabel.text = "N/A"
        }
    }

    @objc private func endButtonWasTapped() {
        if progressWasMade {
            let alertController = UIAlertController(title: "End the game?", message: "All current progress will be lost!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "End Game", style: .destructive) { _ in
                self.navigateToMainMenu()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alertController, animated: true, completion: nil)
        } else {
            navigateToMainMenu()
        }
    }

    @objc private func restartButtonWasTapped() {
        if progressWasMade {
            let alertController = UIAlertController(title: "Restart the game?", message: "All current progress will be lost!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Restart", style: .destructive) { _ in
                self.resetBoardWithAnimation()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alertController, animated: true, completion: nil)
        } else {
            resetBoardWithAnimation()
        }
    }

    private func resetBoardWithAnimation() {
        UIView.springReload(views: [boardView, bestTimeStat.valueLabel, timeStat.valueLabel, movesStat.valueLabel], reloadBlock: resetBoard)
    }

    private func navigateToMainMenu() {
        dismiss(animated: false, completion: nil)
    }

    @objc private func displayResetBestTimePrompt(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard bestTimesController.getBestTime(for: boardConfiguration.name) != nil else { return }

        let boardName = boardConfiguration.name.capitalized
        let alertController = UIAlertController(title: "Reset your best time?", message: "Saved best time for the \(boardName) board will be discarded. This cannot be undone.", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Reset Best Time", style: .destructive) { _ in
            self.resetBestTime()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

    private func resetBestTime() {
        _ = bestTimesController.resetBestTime(for: boardConfiguration.name)
        UIView.springReload(views: [bestTimeStat.valueLabel], reloadBlock: updateBestTimeStat)
    }

    @objc private func updateTimeStat() {
        timeStat.valueLabel.text = GameViewController.secondsToTimeString(elapsedSeconds)
    }

    private func boardWasSolved() {
        timeStatRefresher.isPaused = true

        let updateResult = bestTimesController.boardWasSolved(board: boardConfiguration.name, seconds: elapsedSeconds)
        let message: String

        switch updateResult {
        case .created:
            message = "Congratulations on your first solve!"
        case let .replaced(oldTime):
            message = String(format: "New record! Your previous record was %.1f s.", oldTime)
        case let .preserved(bestTime):
            message = String(format: "Play again to beat your %.1f s record!", bestTime)
        }

        updateTimeStat()

        let title = String(format: "Your time was %.1f s!", elapsedSeconds)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Play Again", style: .default, handler: { _ in
            self.resetBoardWithAnimation()
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
        guard let canPerformMoveOperation = board.canPerform(moveOperation) else {
            return nil
        }

        if let _ = operationsInProgress.first(where: { $0.targetPosition == moveOperation.targetPosition }) {
            return false
        }

        return canPerformMoveOperation
    }

    func boardView(_ boardView: BoardView, didStart moveOperation: TileMoveOperation) {
        if self.boardView(boardView, canPerform: moveOperation) ?? false {
            operationsInProgress.insert(moveOperation)
        } else {
            fatalError("Move operation not allowed")
        }
    }

    func boardView(_ boardView: BoardView, didCancel moveOperation: TileMoveOperation) {
        guard let _ = operationsInProgress.remove(moveOperation) else {
            fatalError("Move operation was cancelled before it started")
        }
    }

    func boardView(_ boardView: BoardView, didComplete moveOperation: TileMoveOperation) {
        guard let _ = operationsInProgress.remove(moveOperation) else {
            fatalError("Move operation was completed before it started")
        }

        board.perform(moveOperation)
        moves += 1

        if board.isSolved && operationsInProgress.isEmpty { boardWasSolved() }
    }
}
