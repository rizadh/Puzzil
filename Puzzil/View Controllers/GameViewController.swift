//
//  GameViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorTheme.selected.background.isLight ? .default : .lightContent
    }

    // MARK: - Board Management

    private let boardStyle: BoardStyle
    private var minProgress: Double!
    private var gameIsRunning = false
    private var resultsAreVisible = false

    // MARK: - Subviews

    let bestTimeStat = StatView()
    let timeStat = StatView()
    let movesStat = StatView()
    let solvedBoardView: StaticBoardView
    let boardView = BoardView()
    let resultView = ResultView()
    let progressBar = UIProgressView(progressViewStyle: .bar)

    // MARK: - Stat Management

    private var timeStatRefresher: CADisplayLink!
    private var startTime = Date()
    private var moves = 0

    private var elapsedSeconds: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }

    private var progressWasMade: Bool {
        return moves > 0
    }

    private static func secondsToTimeString(_ rawSeconds: Double) -> String {
        return String(format: "%.1f s", rawSeconds)
    }

    // MARK: - Controller Dependencies

    var bestTimesController: BestTimesController!

    // MARK: - Constructors

    init(boardStyle: BoardStyle) {
        self.boardStyle = boardStyle
        solvedBoardView = StaticBoardView(board: boardStyle.board)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Method Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorTheme.selected.background

        timeStatRefresher = CADisplayLink(target: self, selector: #selector(updateTimeStatWithoutAnimation))
        timeStatRefresher.preferredFramesPerSecond = 10
        timeStatRefresher.isPaused = true
        timeStatRefresher.add(to: .main, forMode: RunLoop.Mode.default)

        let resetRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(displayResetBestTimePrompt))
        bestTimeStat.addGestureRecognizer(resetRecognizer)

        bestTimeStat.titleLabel.text = "Best Time"
        timeStat.titleLabel.text = "Time"
        movesStat.titleLabel.text = "Moves"

        let stats = UIStackView(arrangedSubviews: [bestTimeStat, timeStat, movesStat])
        stats.translatesAutoresizingMaskIntoConstraints = false
        stats.distribution = .fillEqually

        solvedBoardView.translatesAutoresizingMaskIntoConstraints = false
        solvedBoardView.isHidden = true

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self

        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.isHidden = true

        let endButton = ThemedButton()
        endButton.setImage(UIImage(named: "round_close_black_36pt"), for: .normal)
        endButton.addTarget(self, action: #selector(endButtonWasTapped), for: .primaryActionTriggered)

        let peekButton = ThemedButton()
        peekButton.setImage(UIImage(named: "outline_visibility_black_36pt"), for: .normal)
        peekButton.addTarget(self, action: #selector(peekButtonWasPressed), for: [.touchDown, .touchDragEnter])
        peekButton.addTarget(self, action: #selector(peekButtonWasReleased),
                             for: [.touchUpInside, .touchDragExit, .touchCancel])

        let restartButton = ThemedButton()
        restartButton.setImage(UIImage(named: "round_refresh_black_36pt"), for: .normal)
        restartButton.addTarget(self, action: #selector(restartButtonWasTapped), for: .primaryActionTriggered)

        let buttons = UIStackView()
        buttons.addArrangedSubview(endButton)
        buttons.addArrangedSubview(peekButton)
        buttons.addArrangedSubview(restartButton)
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.distribution = .fillEqually
        buttons.spacing = 8

        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.trackTintColor = ColorTheme.selected.secondary
        progressBar.progressTintColor = ColorTheme.selected.primary
        progressBar.subviews.forEach { $0.clipsToBounds = true; $0.layer.cornerRadius = 4 }
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true

        view.addSubview(stats)
        view.addSubview(boardView)
        view.addSubview(solvedBoardView)
        view.addSubview(resultView)
        view.addSubview(buttons)
        view.addSubview(progressBar)

        let statsLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(statsLayoutGuide)

        NSLayoutConstraint.activate([
            statsLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            stats.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            stats.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            stats.centerYAnchor.constraint(equalTo: statsLayoutGuide.centerYAnchor),
            stats.heightAnchor.constraint(lessThanOrEqualTo: statsLayoutGuide.heightAnchor),

            boardView.leftAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16),
            boardView.rightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16),
            boardView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            boardView.topAnchor.constraint(equalTo: statsLayoutGuide.bottomAnchor, constant: 16),

            solvedBoardView.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            solvedBoardView.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            solvedBoardView.topAnchor.constraint(equalTo: boardView.topAnchor),
            solvedBoardView.bottomAnchor.constraint(equalTo: boardView.bottomAnchor),

            resultView.centerXAnchor.constraint(equalTo: boardView.centerXAnchor),
            resultView.centerYAnchor.constraint(equalTo: boardView.centerYAnchor),

            buttons.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            buttons.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            buttons.topAnchor.constraint(greaterThanOrEqualTo: boardView.bottomAnchor, constant: 16),
            buttons.heightAnchor.constraint(equalToConstant: 48),

            progressBar.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            progressBar.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            progressBar.topAnchor.constraint(equalTo: buttons.bottomAnchor, constant: 8),
            progressBar.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
            progressBar.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),
            progressBar.heightAnchor.constraint(equalToConstant: 8),
        ])

        let optionalConstraints = [
            progressBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            boardView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor),
        ]
        optionalConstraints.forEach { $0.priority = .defaultHigh }
        NSLayoutConstraint.activate(optionalConstraints)

        updateBestTimeStat(animated: false)
        updateMovesStat(animated: false)
        updateTimeStat(animated: false)

        boardView.reloadBoard()
    }

    override func viewDidDisappear(_ animated: Bool) {
        timeStatRefresher.invalidate()
    }

    // MARK: Public Methods

    func beginGame() {
        if resultsAreVisible {
            boardView.isHidden = false
            boardView.reloadBoard()

            UIView.animatedSwap(outgoingView: resultView, incomingView: boardView, midCompletion: {
                self.resultsAreVisible = false
            }, completion: resetBoard)
        } else {
            resetBoard()
        }
    }

    func resetBoard() {
        gameIsRunning = true
        boardView.reloadBoard()
        progressBar.progress = 0
        resetStats()
    }

    // MARK: - Private Methods

    private func resetStats() {
        moves = 0
        startTime = Date()

        updateBestTimeStat(animated: true)
        updateTimeStat(animated: true)
        updateMovesStat(animated: true)
    }

    private func boardFromConfiguration() -> Board {
        return boardStyle.board
    }

    private func navigateToMainMenu() {
        gameIsRunning = false
        dismiss(animated: true)
    }

    private func boardWasSolved() {
        gameIsRunning = false

        resultView.result = bestTimesController.boardWasSolved(boardStyle: boardStyle, seconds: elapsedSeconds)

        resetStats()

        solvedBoardView.isHidden = true

        UIView.animatedSwap(outgoingView: boardView, incomingView: resultView) {
            self.resultsAreVisible = true
        }
    }

    // MARK: - Stat Management

    private func updateBestTimeStat(animated: Bool) {
        let newValue: String

        if !gameIsRunning {
            newValue = "—"
        } else if let bestTime = bestTimesController.getBestTime(for: boardStyle) {
            newValue = GameViewController.secondsToTimeString(bestTime)
        } else {
            newValue = "N/A"
        }

        updateStat(bestTimeStat, newValue: newValue, animated: animated)
    }

    @objc private func updateTimeStatWithoutAnimation() {
        updateTimeStat(animated: false)
    }

    private func updateTimeStat(animated: Bool) {
        timeStatRefresher.isPaused = true

        if gameIsRunning {
            updateStat(timeStat, newValue: GameViewController.secondsToTimeString(elapsedSeconds), animated: animated) { _ in
                self.timeStatRefresher.isPaused = !self.gameIsRunning
            }
        } else {
            updateStat(timeStat, newValue: "—", animated: animated) { _ in
                self.timeStatRefresher.isPaused = !self.gameIsRunning
            }
        }
    }

    private func updateMovesStat(animated: Bool) {
        if gameIsRunning {
            updateStat(movesStat, newValue: moves.description, animated: animated)
        } else {
            updateStat(movesStat, newValue: "—", animated: animated)
        }
    }

    private func updateStat(_ statView: StatView, newValue: String, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let oldValue = statView.valueLabel.text

        if animated && newValue != oldValue {
            statView.valueLabel.springReload(reloadBlock: { _ in
                statView.valueLabel.text = newValue
            }, completion: completion)
        } else {
            statView.valueLabel.text = newValue
            completion?(true)
        }
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
                self.beginGame()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alertController, animated: true)
        } else {
            beginGame()
        }
    }

    @objc private func peekButtonWasPressed() {
        guard gameIsRunning else { return }

        boardView.isHidden = true
        solvedBoardView.isHidden = false
    }

    @objc private func peekButtonWasReleased() {
        guard gameIsRunning else { return }

        boardView.isHidden = false
        solvedBoardView.isHidden = true
    }

    @objc private func displayResetBestTimePrompt(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard bestTimesController.getBestTime(for: boardStyle) != nil else { return }

        let boardName = boardStyle.rawValue.capitalized
        let alertController = UIAlertController(title: "Reset your best time?", message: "Saved best time for the \(boardName) board will be discarded. This cannot be undone.", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Reset Best Time", style: .destructive) { _ in
            _ = self.bestTimesController.resetBestTime(for: self.boardStyle)
            self.updateBestTimeStat(animated: true)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true)
    }
}

// MARK: - BoardViewDelegate Conformance

extension GameViewController: BoardViewDelegate {
    func newBoard(for boardView: BoardView) -> Board {
        if gameIsRunning {
            var board = boardStyle.board
            board.shuffle()
            minProgress = board.progress
            return board
        } else {
            return boardStyle.board.clearingAllTiles()
        }
    }

    func boardDidChange(_ boardView: BoardView) {
        guard gameIsRunning else { return }

        moves += 1

        if boardView.board.isSolved { boardWasSolved() }
        else { updateMovesStat(animated: false) }
    }

    func progressDidChange(_ boardView: BoardView) {
        let progress = boardView.progress
        minProgress = min(progress, minProgress)
        let mappedProgress = (progress - minProgress) / (1 - minProgress)
        progressBar.setProgress(Float(mappedProgress), animated: false)
    }
}
