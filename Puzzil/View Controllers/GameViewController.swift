//
//  GameViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

private let outerLeftTransform = CGAffineTransform(translationX: -200, y: 50).scaledBy(x: 0.5, y: 0.5).rotated(by: -.pi / 16)
private let outerRightTransform = CGAffineTransform(translationX: 200, y: 50).scaledBy(x: 0.5, y: 0.5).rotated(by: .pi / 16)

class GameViewController: UIViewController {
    enum GameState {
        case waiting
        case running(startTime: Date, moves: Int)
        case solved
        case transitioning
    }

    // MARK: UIViewController Property Overrides

    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch ColorTheme.selected {
        case .light:
            return .default
        case .dark:
            return .lightContent
        }
    }

    // MARK: - Board Management

    private let boardStyle: BoardStyle
    private var minimumProgress: Double!
    private var gameState: GameState = .transitioning {
        didSet {
            switch gameState {
            case .waiting:
                endButton.isEnabled = true
                peekButton.isEnabled = true
                restartButton.isEnabled = true
                timeStatRefresher.isPaused = true
            case .running:
                endButton.isEnabled = true
                peekButton.isEnabled = true
                restartButton.isEnabled = true
                timeStatRefresher.isPaused = false
            case .solved:
                endButton.isEnabled = true
                peekButton.isEnabled = false
                restartButton.isEnabled = true
                timeStatRefresher.isPaused = true
            case .transitioning:
                endButton.isEnabled = true
                peekButton.isEnabled = false
                restartButton.isEnabled = false
                timeStatRefresher.isPaused = true
            }
        }
    }

    // MARK: - Subviews

    let stats = UIStackView()
    let bestTimeStat = StatView()
    let timeStat = StatView()
    let movesStat = StatView()
    let solvedBoardView: StaticBoardView
    let boardView = BoardView()
    let resultView = ResultView()
    let progressBar = UIProgressView(progressViewStyle: .default)
    let endButton = ThemedButton()
    let peekButton = ThemedButton()
    let restartButton = ThemedButton()
    let buttons = UIStackView()

    // MARK: - Stat Management Properties

    private var timeStatRefresher: CADisplayLink!
    private var statsBeingReloaded = Set<StatView>()

    // MARK: - Static Helper Methods

    private static func secondsToTimeString(_ rawSeconds: Double) -> String {
        return String(format: "%.1f s", rawSeconds)
    }

    // MARK: - Constructors

    init(boardStyle: BoardStyle) {
        self.boardStyle = boardStyle
        solvedBoardView = StaticBoardView(board: boardStyle.board)

        super.init(nibName: nil, bundle: nil)

        transitioningDelegate = self
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

        let resetRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(bestTimeWasLongPressed))
        bestTimeStat.addGestureRecognizer(resetRecognizer)

        bestTimeStat.titleLabel.text = "Best Time"
        timeStat.titleLabel.text = "Time"
        movesStat.titleLabel.text = "Moves"

        [bestTimeStat, timeStat, movesStat].forEach(stats.addArrangedSubview(_:))
        stats.translatesAutoresizingMaskIntoConstraints = false
        stats.distribution = .fillEqually

        solvedBoardView.translatesAutoresizingMaskIntoConstraints = false
        solvedBoardView.isHidden = true

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self

        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.isHidden = true

        endButton.setImage(UIImage(named: "round_close_black_36pt"), for: .normal)
        endButton.addTarget(self, action: #selector(endButtonWasTapped), for: .primaryActionTriggered)

        peekButton.setImage(UIImage(named: "outline_visibility_black_36pt"), for: .normal)
        peekButton.addTarget(self, action: #selector(peekButtonWasPressed), for: [.touchDown, .touchDragEnter])
        peekButton.addTarget(self, action: #selector(peekButtonWasReleased),
                             for: [.touchUpInside, .touchDragExit, .touchCancel])

        restartButton.setImage(UIImage(named: "round_refresh_black_36pt"), for: .normal)
        restartButton.addTarget(self, action: #selector(restartButtonWasTapped), for: .primaryActionTriggered)

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
        optionalConstraints.forEach { $0.priority = .defaultLow + 1 }
        NSLayoutConstraint.activate(optionalConstraints)

        updateBestTimeStat(animated: false)
        updateMovesStat(animated: false)
        updateTimeStat(animated: false)

        boardView.reloadBoard()

        BestTimesController.shared.subscribeToChanges { [weak self] in
            DispatchQueue.main.async {
                self?.updateBestTimeStat(animated: true)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        gameState = .waiting
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        gameState = .transitioning
    }

    override func viewDidDisappear(_ animated: Bool) {
        timeStatRefresher.invalidate()
    }

    // MARK: - View Transitioning

    private func reloadBoard() {
        // Animate outgoing view

        let outgoingView: UIView
        let outgoingAnimator = UIViewPropertyAnimator(duration: 0.125, curve: .easeIn)

        switch gameState {
        case .waiting, .running:
            let snapshotView = boardView.snapshotView(afterScreenUpdates: false)!
            snapshotView.frame = boardView.frame
            view.insertSubview(snapshotView, belowSubview: boardView)
            outgoingView = snapshotView
            outgoingAnimator.addCompletion { _ in
                snapshotView.removeFromSuperview()
            }
        case .solved:
            outgoingView = resultView
            outgoingAnimator.addCompletion { _ in
                self.resultView.isHidden = true
            }
        case .transitioning:
            return
        }

        outgoingAnimator.addAnimations {
            outgoingView.transform = outerLeftTransform
            outgoingView.alpha = 0
        }
        outgoingAnimator.startAnimation()

        // Animate incoming view

        boardView.reloadBoard()
        boardView.transform = outerRightTransform
        boardView.alpha = 0
        boardView.isHidden = false
        let incomingAnimator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1) {
            self.boardView.transform = .identity
            self.boardView.alpha = 1
        }
        incomingAnimator.addCompletion { _ in
            self.gameState = .waiting
        }
        incomingAnimator.startAnimation()

        // Set state variable and reset stats

        gameState = .transitioning
        updateAllStats()
        progressBar.setProgress(0, animated: true)
    }

    private func showResult() {
        guard case let .running(startTime, _) = gameState else { fatalError("Board was solved before game ran.") }
        gameState = .solved

        let boardAnimator = UIViewPropertyAnimator(duration: 0.125, curve: .easeIn) {
            self.boardView.transform = outerLeftTransform
            self.boardView.alpha = 0
        }
        boardAnimator.addCompletion { _ in
            self.boardView.isHidden = true
        }
        boardAnimator.startAnimation()

        resultView.result = BestTimesController.shared.saveBestTime(-startTime.timeIntervalSinceNow, for: boardStyle)

        resultView.isHidden = false
        resultView.transform = outerRightTransform
        resultView.alpha = 0
        let resultAnimator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 0.8) {
            self.resultView.transform = .identity
            self.resultView.alpha = 1
        }
        resultAnimator.startAnimation()

        updateAllStats()
    }

    private func navigateToMainMenu() {
        gameState = .transitioning
        dismiss(animated: true)
    }

    // MARK: - Stat Update Methods

    private func updateStat(_ statView: StatView, newValue: String, animated: Bool) {
        if statsBeingReloaded.contains(statView) { return }

        guard statView.valueLabel.text != newValue else { return }

        if animated {
            statsBeingReloaded.insert(statView)

            let exitAnimator = UIViewPropertyAnimator(duration: 0.125, curve: .easeIn) {
                statView.valueLabel.transform = CGAffineTransform(scaleX: 1e-5, y: 1e-5)
            }
            exitAnimator.addCompletion { _ in
                statView.valueLabel.text = newValue
                self.statsBeingReloaded.remove(statView)
            }
            exitAnimator.startAnimation()

            UIViewPropertyAnimator(duration: 0.25, dampingRatio: 0.8) {
                statView.valueLabel.transform = .identity
            }.startAnimation(afterDelay: 0.125)
        } else {
            statView.valueLabel.text = newValue
        }
    }

    private func updateBestTimeStat(animated: Bool) {
        switch gameState {
        case .waiting, .running, .transitioning:
            if let bestTime = BestTimesController.shared.getBestTime(for: boardStyle) {
                let timeString = GameViewController.secondsToTimeString(bestTime)
                updateStat(bestTimeStat, newValue: timeString, animated: animated)
            } else {
                updateStat(bestTimeStat, newValue: "N/A", animated: animated)
            }
        case .solved:
            updateStat(bestTimeStat, newValue: "—", animated: animated)
        }
    }

    @objc private func updateTimeStatWithoutAnimation() {
        updateTimeStat(animated: false)
    }

    private func updateTimeStat(animated: Bool) {
        switch gameState {
        case let .running(startTime, _):
            let elapsedTime = -startTime.timeIntervalSinceNow
            let timeString = GameViewController.secondsToTimeString(elapsedTime)
            updateStat(timeStat, newValue: timeString, animated: animated)
        case .waiting, .solved, .transitioning:
            updateStat(timeStat, newValue: "—", animated: animated)
        }
    }

    private func updateMovesStat(animated: Bool) {
        switch gameState {
        case .waiting, .transitioning:
            updateStat(movesStat, newValue: "0", animated: animated)
        case let .running(_, moves):
            updateStat(movesStat, newValue: moves.description, animated: animated)
        case .solved:
            updateStat(movesStat, newValue: "—", animated: animated)
        }
    }

    private func updateAllStats() {
        updateBestTimeStat(animated: true)
        updateMovesStat(animated: true)
        updateTimeStat(animated: true)
    }

    // MARK: - Event Handlers

    @objc private func endButtonWasTapped() {
        switch gameState {
        case let .running(_, moves) where moves > 0:
            let alertController = UIAlertController(title: "End the game?", message: "All current progress will be lost!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "End Game", style: .destructive) { _ in
                self.navigateToMainMenu()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alertController, animated: true)
        default:
            navigateToMainMenu()
        }
    }

    @objc private func restartButtonWasTapped() {
        switch gameState {
        case let .running(_, moves) where moves > 0:
            let alertController = UIAlertController(title: "Restart the game?", message: "All current progress will be lost!", preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: "Restart", style: .destructive) { _ in
                self.reloadBoard()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alertController, animated: true)
        default:
            reloadBoard()
        }
    }

    @objc private func peekButtonWasPressed() {
        boardView.isHidden = true
        solvedBoardView.isHidden = false
    }

    @objc private func peekButtonWasReleased() {
        boardView.isHidden = false
        solvedBoardView.isHidden = true
    }

    @objc private func bestTimeWasLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard BestTimesController.shared.getBestTime(for: boardStyle) != nil else { return }

        let boardName = boardStyle.rawValue.capitalized
        let alertController = UIAlertController(title: "Reset your best time?", message: "Saved best time for the \(boardName) board will be discarded. This cannot be undone.", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Reset Best Time", style: .destructive) { _ in
            BestTimesController.shared.removeBestTime(for: self.boardStyle)
            self.updateBestTimeStat(animated: true)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true)
    }
}

// MARK: - BoardViewDelegate Conformance

extension GameViewController: BoardViewDelegate {
    func newBoard(for boardView: BoardView) -> Board {
        var board = boardStyle.board
        board.shuffle()
        minimumProgress = board.progress
        return board
    }

    func boardDidChange(_ boardView: BoardView) {
        switch gameState {
        case .waiting:
            gameState = .running(startTime: Date(), moves: 1)
            updateTimeStat(animated: true)
        case let .running(startTime, moves):
            gameState = .running(startTime: startTime, moves: moves + 1)
        default:
            fatalError("Invalid game state for board change.")
        }

        if boardView.board.isSolved { showResult() }
        else { updateMovesStat(animated: false) }
    }

    func progressDidChange(_ boardView: BoardView, incremental: Bool) {
        let progress = boardView.progress
        minimumProgress = min(progress, minimumProgress)
        let mappedProgress = (progress - minimumProgress) / (1 - minimumProgress)
        progressBar.setProgress(Float(mappedProgress), animated: !incremental)
    }
}

// MARK: - UIViewControllerTransitioningDelegate Conformance

extension GameViewController: UIViewControllerTransitioningDelegate {
    class Animator: NSObject, UIViewControllerAnimatedTransitioning {
        let transitionDuration = 0.25
        var isPresenting = true

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return transitionDuration
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let mainViewController = transitionContext
                .viewController(forKey: isPresenting ? .from : .to) as! MainViewController
            let gameViewController = transitionContext
                .viewController(forKey: isPresenting ? .to : .from) as! GameViewController
            let containerView = transitionContext.containerView

            let selectedCell = mainViewController.collectionView.cellForItem(at: [0, mainViewController.selectedItem]) as! BoardCell
            let selectedBoard = selectedCell.lastSnapshotView!
            let selectedBoardFrameInContainer = containerView.convert(selectedBoard.bounds, from: selectedBoard)
            let selectedBoardSnapshot = selectedBoard.snapshotView(afterScreenUpdates: true)!

            gameViewController.view.frame = containerView.bounds
            gameViewController.view.layoutIfNeeded()
            let gameBoard = gameViewController.boardView
            let gameBoardFrameInContainer = containerView.convert(gameBoard.bounds, from: gameBoard)

            let staticBoard = StaticBoardView(board: gameBoard.board)
            staticBoard.frame = gameBoardFrameInContainer
            let gameBoardSnapshot = staticBoard.snapshotView(afterScreenUpdates: true)!

            gameBoard.alpha = 0
            selectedBoard.alpha = 0

            let initialFrame = isPresenting ? selectedBoardFrameInContainer : gameBoardFrameInContainer
            let finalFrame = isPresenting ? gameBoardFrameInContainer : selectedBoardFrameInContainer

            selectedBoardSnapshot.frame = initialFrame
            gameBoardSnapshot.frame = initialFrame
            if isPresenting {
                containerView.addSubview(gameViewController.view)
                containerView.addSubview(selectedBoardSnapshot)
                containerView.addSubview(gameBoardSnapshot)

                gameBoardSnapshot.alpha = 0
                gameViewController.view.alpha = 0
            } else {
                containerView.addSubview(mainViewController.view)
                containerView.addSubview(gameBoardSnapshot)
                containerView.addSubview(selectedBoardSnapshot)

                selectedBoardSnapshot.alpha = 0
                mainViewController.view.alpha = 0
            }

            let animator = UIViewPropertyAnimator(duration: transitionDuration, dampingRatio: 1) {
                selectedBoardSnapshot.frame = finalFrame
                gameBoardSnapshot.frame = finalFrame

                if self.isPresenting {
                    selectedBoardSnapshot.alpha = 0
                    gameBoardSnapshot.alpha = 1
                    gameViewController.view.alpha = 1
                } else {
                    selectedBoardSnapshot.alpha = 1
                    gameBoardSnapshot.alpha = 0
                    mainViewController.view.alpha = 1
                }
            }
            animator.addCompletion { _ in
                transitionContext.completeTransition(true)
                gameBoard.alpha = 1
                selectedBoard.alpha = 1
                selectedBoardSnapshot.removeFromSuperview()
                gameBoardSnapshot.removeFromSuperview()
            }
            animator.startAnimation()
        }
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Animator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = Animator()
        animator.isPresenting = false
        return animator
    }
}
