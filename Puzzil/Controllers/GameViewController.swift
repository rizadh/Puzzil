//
//  GameViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {

    // MARK: UIViewController Property Overrides

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIColor.themeBackground.isLight ? .default : .lightContent
    }

    // MARK: - Queues

    private lazy var boardWaitQueue = DispatchQueue(
        label: "com.rizadh.Puzzil.GameViewController.boardWaitQueue.\(boardStyle.rawValue)", qos: .utility)

    // MARK: - Board Management

    private let boardStyle: BoardStyle
    private lazy var originalBoard = boardStyle.board
    private let difficulty: Double
    private var boardIsScrambling = false
    private var gameIsRunning = false {
        didSet {
            restartButton.isEnabled = (gameIsRunning || resultsAreVisible) && nextBoardIsReady
            endButton.isEnabled = gameIsRunning || resultsAreVisible
        }
    }

    private var resultsAreVisible = false {
        didSet {
            restartButton.isEnabled = (gameIsRunning || resultsAreVisible) && nextBoardIsReady
            endButton.isEnabled = gameIsRunning || resultsAreVisible
        }
    }

    private var nextBoardIsReady = false {
        didSet {
            restartButton.isEnabled = (gameIsRunning || resultsAreVisible) && nextBoardIsReady
        }
    }

    // MARK: - Subviews

    let stats = UIStackView()
    let bestTimeStat = StatView()
    let timeStat = StatView()
    let movesStat = StatView()
    let boardView = BoardView()
    let resultView = ResultView()
    let buttons = UIStackView()
    private var endButton: UIButton!
    private var restartButton: UIButton!
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

    private let bestTimesController = (UIApplication.shared.delegate as! AppDelegate).bestTimesController
    private let boardScrambler = (UIApplication.shared.delegate as! AppDelegate).boardScrambler

    private static func secondsToTimeString(_ rawSeconds: Double) -> String {
        return String(format: "%.1f s", rawSeconds)
    }

    // MARK: - Constructors

    init(boardStyle: BoardStyle, difficulty: Double) {
        self.boardStyle = boardStyle
        self.difficulty = difficulty

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Method Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
        setupConstraints()

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
        waitForBoard()
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

    private func setupSubviews() {
        timeStatRefresher = CADisplayLink(target: self, selector: #selector(updateTimeStatWithoutAnimation))
        if #available(iOS 10.0, *) {
            timeStatRefresher.preferredFramesPerSecond = 10
        } else {
            timeStatRefresher.frameInterval = 60 / 10
        }
        timeStatRefresher.isPaused = true
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

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self

        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.isHidden = true

        endButton = UIButton.createThemedButton()
        endButton.addTarget(self, action: #selector(endButtonWasTapped), for: .primaryActionTriggered)
        endButton.isEnabled = false
        endButton.setTitle("End", for: .normal)

        restartButton = UIButton.createThemedButton()
        restartButton.addTarget(self, action: #selector(restartButtonWasTapped), for: .primaryActionTriggered)
        restartButton.isEnabled = false
        restartButton.setTitle("Restart", for: .normal)

        buttons.addArrangedSubview(endButton)
        buttons.addArrangedSubview(restartButton)
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.distribution = .fillEqually
        buttons.spacing = 8

        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.trackTintColor = .themeProgressBarTrack
        progressBar.progressTintColor = .themeProgressBarProgress
        progressBar.subviews.forEach { $0.clipsToBounds = true; $0.layer.cornerRadius = 4 }
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true

        view.addSubview(stats)
        view.addSubview(boardView)
        view.addSubview(resultView)
        view.addSubview(buttons)
        view.addSubview(progressBar)
    }

    private func setupConstraints() {
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

            stats.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            stats.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            stats.centerYAnchor.constraint(equalTo: statsLayoutGuide.centerYAnchor),
            stats.heightAnchor.constraint(lessThanOrEqualTo: statsLayoutGuide.heightAnchor),

            boardView.leftAnchor.constraint(greaterThanOrEqualTo: safeArea.leftAnchor, constant: 16),
            boardView.rightAnchor.constraint(lessThanOrEqualTo: safeArea.rightAnchor, constant: -16),
            boardView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            boardView.topAnchor.constraint(equalTo: statsLayoutGuide.bottomAnchor, constant: 16),

            resultView.timeText.centerXAnchor.constraint(equalTo: boardView.centerXAnchor),
            resultView.timeText.centerYAnchor.constraint(equalTo: boardView.centerYAnchor),

            buttons.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            buttons.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            buttons.topAnchor.constraint(greaterThanOrEqualTo: boardView.bottomAnchor, constant: 16),
            buttons.heightAnchor.constraint(equalToConstant: 48),

            progressBar.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            progressBar.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            progressBar.topAnchor.constraint(equalTo: buttons.bottomAnchor, constant: 8),
            progressBar.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
            progressBar.heightAnchor.constraint(equalToConstant: 8),
        ] + [
            boardView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor),
        ].map {
            $0.priority = .defaultHigh
            return $0
        } + [
            resultView.widthAnchor.constraint(equalTo: boardView.widthAnchor),
        ].map {
            $0.priority = .defaultLow
            return $0
        })
    }

    private func navigateToMainMenu() {
        gameIsRunning = false
        dismiss(animated: true)
    }

    private func boardWasSolved() {
        gameIsRunning = false

        resultView.result = bestTimesController.boardWasSolved(boardStyle: boardStyle, seconds: elapsedSeconds)
        resultView.transform = .zero
        resultView.isHidden = false

        resetStats()

        UIView.animatedSwap(outgoingView: boardView, incomingView: resultView) {
            self.resultsAreVisible = true
        }
    }

    private func waitForBoard() {
        boardWaitQueue.async {
            DispatchQueue.main.async {
                self.nextBoardIsReady = false
            }
            self.boardScrambler.waitForBoard(style: self.boardStyle)
            DispatchQueue.main.async {
                self.nextBoardIsReady = true
            }
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

// MARK: BoardViewDelegate

extension GameViewController: BoardViewDelegate {
    func newBoard(for boardView: BoardView) -> Board {
        if gameIsRunning {
            return boardScrambler.nextBoard(style: boardStyle)
        } else {
            return boardStyle.board.clearingAllTiles()
        }
    }

    func boardDidChange(_ boardView: BoardView) {
        guard gameIsRunning else { return }

        moves += 1
        progressBar.setProgress(Float(boardView.board.progress), animated: true)
        if boardView.board.isSolved { boardWasSolved() }
        else { updateMovesStat(animated: true) }
    }
}
