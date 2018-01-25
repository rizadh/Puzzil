//
//  GameViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, BoardViewDelegate {

    private var originalBoard: Board
    private var board: Board
    private let difficulty: Double

    private let stats = UIStackView()
    private let timeStat = StatView("Time")
    private let moveStat = StatView("Moves")
    private let boardView = BoardView()
    private let buttons = UIStackView()
    private var endButton: RoundedButton!
    private var restartButton: RoundedButton!
    private var gradientView: GradientView!

    private var timeStatRefresher: CADisplayLink!

    private var startTime = Date()
    private var moves = 0

    private var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }

    private var progressWasMade: Bool {
        return moves > 0
    }

    var foregroundViews: [UIView] { return view.subviews.filter { $0 != gradientView } }

    init(board: Board, difficulty: Double) {
        originalBoard = board
        self.board = board
        self.difficulty = difficulty

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        gradientView = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)
        gradientView.frame = view.bounds
        gradientView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(gradientView)

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self

        resetBoard()
        setupSubviews()

        foregroundViews.forEach { $0.alpha = 0 }
        self.boardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let alphaAnimationDuration = 0.1
        let scaleAnimationDuration = 0.25
        let dampingRatio: CGFloat = 1
        let alphaAnimations = { self.foregroundViews.forEach { $0.alpha = 1 } }
        let scaleAnimations = { self.boardView.transform = .identity }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: alphaAnimationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: scaleAnimationDuration, dampingRatio: dampingRatio, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: alphaAnimationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: scaleAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
        }

        boardView.updateGradient(usingPresentationLayer: false)
    }

    private func setupSubviews() {
        timeStatRefresher = CADisplayLink(target: self, selector: #selector(updateTimeStat))
        timeStatRefresher.add(to: .main, forMode: .defaultRunLoopMode)

        stats.addArrangedSubview(moveStat)
        stats.addArrangedSubview(timeStat)
        stats.translatesAutoresizingMaskIntoConstraints = false
        stats.distribution = .fillEqually

        endButton = RoundedButton("End") { [unowned self] _ in
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
        restartButton = RoundedButton("Restart") { [unowned self] _ in
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

        NSLayoutConstraint.activate([
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor),
            buttons.heightAnchor.constraint(equalToConstant: 60),
        ].map {
            $0.priority = .defaultHigh
            return $0
        })

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

    private func resetBoardWithAnimation() {
        let initialAnimationDuration = 0.1
        let initialAlphaAnimations = {
            self.boardView.alpha = 0
            self.stats.alpha = 0
        }
        let initialScaleAnimations = {
            self.boardView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.moveStat.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.timeStat.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }

        let finalAlphaAnimationDuration = 0.1
        let finalScaleAnimationDuration = 0.25
        let finalAlphaAnimations = {
            self.boardView.alpha = 1
            self.stats.alpha = 1
        }
        let finalScaleAnimations = {
            self.boardView.transform = .identity
            self.moveStat.transform = .identity
            self.timeStat.transform = .identity
        }

        let dampingRatio: CGFloat = 0.5

        let triggerFinalAnimation: () -> Void

        if #available(iOS 10.0, *) {
            triggerFinalAnimation = {
                UIViewPropertyAnimator(duration: finalAlphaAnimationDuration, curve: .linear, animations: finalAlphaAnimations).startAnimation()
                UIViewPropertyAnimator(duration: finalScaleAnimationDuration, dampingRatio: dampingRatio, animations: finalScaleAnimations).startAnimation()
            }
        } else {
            triggerFinalAnimation = {
                UIView.animate(withDuration: finalAlphaAnimationDuration, delay: 0, options: .curveLinear, animations: finalAlphaAnimations, completion: nil)
                UIView.animate(withDuration: finalScaleAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: finalScaleAnimations, completion: nil)
            }
        }

        let completion: (Any) -> Void = { _ in
            self.resetBoard()
            triggerFinalAnimation()
        }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: initialAnimationDuration, curve: .linear, animations: initialAlphaAnimations).startAnimation()
            let animator = UIViewPropertyAnimator(duration: initialAnimationDuration, curve: .easeIn, animations: initialScaleAnimations)
            animator.addCompletion(completion)
            animator.startAnimation()
        } else {
            UIView.animate(withDuration: initialAnimationDuration, delay: 0, options: .curveLinear, animations: initialAlphaAnimations, completion: nil)
            UIView.animate(withDuration: initialAnimationDuration, delay: 0, options: .curveEaseIn, animations: initialScaleAnimations, completion: completion)
        }
    }

    private func navigateToMainMenu() {
        let animationDuration = 0.1
        let alphaAnimations = { self.foregroundViews.forEach { $0.alpha = 0 }}
        let scaleAnimations = { self.boardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) }

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
        updateMoveStat()

        if board.isSolved { boardWasSolved() }
    }
}

