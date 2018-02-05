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
            movesStat.value = moves.description
        }
    }

    private var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }

    private var progressWasMade: Bool {
        return moves > 0
    }

    private var bestTimeOrNil: Double? {
        get { return (UIApplication.shared.delegate as! AppDelegate).bestTimes[boardConfiguration.name] }
        set { (UIApplication.shared.delegate as! AppDelegate).bestTimes[boardConfiguration.name] = newValue }
    }

    static private func secondsToTimeString(_ rawSeconds: Double) -> String {
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

        view.subviews.forEach { $0.alpha = 0 }
        boardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        stats.transform = CGAffineTransform(translationX: 0, y: 32)
        buttons.transform = CGAffineTransform(translationX: 0, y: -32)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let alphaAnimationDuration = 0.1
        let scaleAnimationDuration = 0.25
        let dampingRatio: CGFloat = 1
        let alphaAnimations = { self.view.subviews.forEach { $0.alpha = 1 } }
        let scaleAnimations = {
            self.boardView.transform = .identity
            self.stats.transform = .identity
            self.buttons.transform = .identity
        }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: alphaAnimationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: scaleAnimationDuration, dampingRatio: dampingRatio, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: alphaAnimationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: scaleAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
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

        bestTimeStat.title = "Best Time"
        timeStat.title = "Time"
        movesStat.title = "Moves"

        stats.addArrangedSubview(bestTimeStat)
        stats.addArrangedSubview(timeStat)
        stats.addArrangedSubview(movesStat)
        stats.translatesAutoresizingMaskIntoConstraints = false
        stats.distribution = .fillEqually

        endButton = UIButton.themedButton()
        endButton.addTarget(self, action: #selector(endButtonWasTapped), for: .primaryActionTriggered)
        endButton.setTitle("End", for: .normal)

        restartButton = UIButton.themedButton()
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
        if let bestTime = bestTimeOrNil {
            bestTimeStat.value = GameViewController.secondsToTimeString(bestTime)
        } else {
            bestTimeStat.value = "N/A"
        }
    }

    @objc private func endButtonWasTapped() {
        if self.progressWasMade {
            let alertController = UIAlertController(title: "End the game?", message: "All current progress will be lost!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "End Game", style: .destructive) { _ in
                self.navigateToMainMenu()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alertController, animated: true, completion: nil)
        } else {
            self.navigateToMainMenu()
        }
    }

    @objc private func restartButtonWasTapped() {
        if self.progressWasMade {
            let alertController = UIAlertController(title: "Restart the game?", message: "All current progress will be lost!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Restart", style: .destructive) { _ in
                self.resetBoardWithAnimation()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alertController, animated: true, completion: nil)
        } else {
            self.resetBoardWithAnimation()
        }
    }

    private func resetBoardWithAnimation() {
        UIView.springReload(views: [boardView, bestTimeStat, timeStat, movesStat], reloadBlock: resetBoard)
    }

    private func navigateToMainMenu() {
        let animationDuration = 0.1
        let alphaAnimations = { self.view.subviews.forEach { $0.alpha = 0 } }
        let scaleAnimations = {
            self.boardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.stats.transform = CGAffineTransform(translationX: 0, y: 32)
            self.buttons.transform = CGAffineTransform(translationX: 0, y: -32)
        }

        let completion: (Any) -> Void = { _ in
            self.dismiss(animated: false, completion: nil)
        }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: animationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            let animator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeIn, animations: scaleAnimations)
            animator.addCompletion(completion)
            animator.startAnimation()
        } else {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseIn, animations: scaleAnimations, completion: completion)
        }
    }

    @objc private func displayResetBestTimePrompt(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard bestTimeOrNil != nil else { return }

        let boardName = boardConfiguration.name.capitalized
        let alertController = UIAlertController(title: "Reset your best time?", message: "Saved best time for the \(boardName) board will be discarded. This cannot be undone.", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Reset Best Time", style: .destructive) { _ in
            self.resetBestTime()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

    private func resetBestTime() {
        bestTimeOrNil = nil
        UIView.springReload(views: [bestTimeStat], reloadBlock: updateBestTimeStat)
    }

    @objc private func updateTimeStat() {
        timeStat.value = GameViewController.secondsToTimeString(elapsedTime)
    }

    private func boardWasSolved() {
        timeStatRefresher.isPaused = true

        if elapsedTime < bestTimeOrNil ?? Double.greatestFiniteMagnitude {
            bestTimeOrNil = elapsedTime
        }

        updateTimeStat()

        let title = "Solved in \(moves) moves and \((elapsedTime * 100).rounded() / 100) seconds!"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { _ in
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
        return board.canPerform(moveOperation)
    }

    func boardView(_ boardView: BoardView, didPerform moveOperation: TileMoveOperation) {
        board.perform(moveOperation)
        moves += 1

        if board.isSolved { boardWasSolved() }
    }
}
