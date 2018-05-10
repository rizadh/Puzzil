//
//  GameViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, BoardContainer {

    // MARK: UIViewController Property Overrides

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.themeBackground.isLight {
            return .default
        } else {
            return .lightContent
        }
    }

    // MARK: - Board Management

    private var boardConfiguration: BoardConfiguration
    private let difficulty: Double

    // MARK: - Subviews

    let stats = UIStackView()
    let bestTimeStat = StatView()
    let timeStat = StatView()
    let movesStat = StatView()
    let boardView = BoardView()
    let buttons = UIStackView()
    private var endButton: UIButton!
    private var restartButton: UIButton!

    // MARK: - Stat Management

    private var isAwaitingBoard = true {
        didSet {
            restartButton.isEnabled = !isAwaitingBoard
        }
    }

    private var timeStatRefresher: CADisplayLink!
    private var startTime = Date()
    private var moves = 0

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

    // MARK: - Constructors

    init(boardConfiguration: BoardConfiguration, difficulty: Double) {
        self.boardConfiguration = boardConfiguration
        self.difficulty = difficulty

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Method Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self

        setupSubviews()
        updateStats()
        boardView.reloadBoard()
    }

    override func viewDidDisappear(_ animated: Bool) {
        timeStatRefresher.invalidate()
    }

    // MARK: - Private Methods

    private func resetBoard() {
        UIView.springReload(views: [boardView, bestTimeStat.valueLabel, timeStat.valueLabel, movesStat.valueLabel]) {
            self.isAwaitingBoard = true
            self.updateStats()
            self.boardView.reloadBoard()
        }
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

    private func navigateToMainMenu() {
        dismiss(animated: true)
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
            self.resetBoard()
        }))

        present(alert, animated: true)
    }

    // MARK: - Stat Management

    private func updateBestTimeStat() {
        if let bestTime = bestTimesController.getBestTime(for: boardConfiguration.name) {
            bestTimeStat.valueLabel.text = GameViewController.secondsToTimeString(bestTime)
        } else {
            bestTimeStat.valueLabel.text = "N/A"
        }
    }

    @objc private func updateTimeStat() {
        if isAwaitingBoard {
            timeStat.valueLabel.text = "-"
        } else {
            timeStat.valueLabel.text = GameViewController.secondsToTimeString(elapsedSeconds)
        }
    }

    private func updateMovesStat() {
        if isAwaitingBoard {
            movesStat.valueLabel.text = "-"
        } else {
            movesStat.valueLabel.text = moves.description
        }
    }

    private func updateStats() {
        updateBestTimeStat()
        updateTimeStat()
        updateMovesStat()
    }

    // MARK: - Event Handlers

    @objc private func endButtonWasTapped() {
        if progressWasMade {
            let alertController = UIAlertController(title: "End the game?", message: "All current progress will be lost!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "End Game", style: .destructive) { _ in
                self.navigateToMainMenu()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alertController, animated: true)
        } else {
            navigateToMainMenu()
        }
    }

    @objc private func restartButtonWasTapped() {
        if progressWasMade {
            let alertController = UIAlertController(title: "Restart the game?", message: "All current progress will be lost!", preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: "Restart", style: .destructive) { _ in
                self.resetBoard()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alertController, animated: true)
        } else {
            resetBoard()
        }
    }

    @objc private func displayResetBestTimePrompt(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard bestTimesController.getBestTime(for: boardConfiguration.name) != nil else { return }

        let boardName = boardConfiguration.name.capitalized
        let alertController = UIAlertController(title: "Reset your best time?", message: "Saved best time for the \(boardName) board will be discarded. This cannot be undone.", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Reset Best Time", style: .destructive) { _ in
            _ = self.bestTimesController.resetBestTime(for: self.boardConfiguration.name)
            self.updateBestTimeStat()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true)
    }
}

// MARK: BoardViewDelegate

extension GameViewController: BoardViewDelegate {
    func newBoard(for boardView: BoardView, _ completion: @escaping (Board) -> Void) {
        DispatchQueue.global().async {
            var board = self.boardFromConfiguration()
            do { board = try BoardScrambler.scramble(board, untilProgressIsBelow: 1 - self.difficulty)
            } catch BoardScramblerError.scrambleStagnated { self.navigateToMainMenu() }
            catch { fatalError(error.localizedDescription) }

            DispatchQueue.main.async {
                completion(board)
            }
        }
    }

    func expectedBoardDimensions(_ boardView: BoardView) -> (rowCount: Int, columnCount: Int) {
        let board = boardFromConfiguration()
        return (board.rowCount, board.columnCount)
    }

    func boardDidChange(_ boardView: BoardView) {
        moves += 1
        if boardView.board.isSolved { boardWasSolved() }
    }

    func boardWasPresented(_ boardView: BoardView) {
        isAwaitingBoard = false
        moves = 0
        startTime = Date()

        updateStats()
    }
}
