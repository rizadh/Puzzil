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

    private let stats = UIStackView()
    private let timeStat = StatView("Time")
    private let moveStat = StatView("Moves")
    private let boardView = BoardView()
    private let buttons = UIStackView()
    private var backButton: RoundedButton!
    private var restartButton: RoundedButton!

    private var viewsToTransition: [UIView] {
        return [moveStat, timeStat, boardView, backButton, restartButton]
    }

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

    override func viewWillAppear(_ animated: Bool) {
        for view in viewsToTransition {
            view.alpha = 0
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        for view in viewsToTransition {
            view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }

        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1) {
                for view in self.viewsToTransition {
                    view.alpha = 1
                    view.transform = .identity
                }
            }

            animator.startAnimation()
        } else {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: {
                for view in self.viewsToTransition {
                    view.alpha = 1
                    view.transform = .identity
                }
            }, completion: nil)
        }
    }

    private func setupSubviews() {
        timeStatRefresher = CADisplayLink(target: self, selector: #selector(updateTimeStat))
        timeStatRefresher.add(to: .main, forMode: .defaultRunLoopMode)

        stats.addArrangedSubview(moveStat)
        stats.addArrangedSubview(timeStat)
        stats.translatesAutoresizingMaskIntoConstraints = false
        stats.distribution = .fillEqually

        backButton = RoundedButton() { [unowned self] _ in
            if #available(iOS 10.0, *) {
                let animator = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn) {
                    for view in self.viewsToTransition {
                        view.alpha = 0
                        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    }
                }

                animator.addCompletion() { _ in
                    self.dismiss(animated: false, completion: nil)
                }

                animator.startAnimation()
            } else {
                UIView.animate(withDuration: 0.1, animations: {
                    for view in self.viewsToTransition {
                        view.alpha = 0
                        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    }
                }, completion: { _ in
                    self.dismiss(animated: false, completion: nil)
                })
            }
        }

        backButton.text = "Back"
        restartButton = RoundedButton() { [unowned self] _ in
            self.resetBoardWithAnimation()
        }
        restartButton.text = "Restart"

        buttons.addArrangedSubview(backButton)
        buttons.addArrangedSubview(restartButton)
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

    private func resetBoardWithAnimation() {
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn) {
                self.boardView.alpha = 0
                self.boardView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }

            animator.addCompletion { _ in
                self.resetBoard()

                let returnAnimator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1) {
                    self.boardView.alpha = 1
                    self.boardView.transform = .identity
                }

                returnAnimator.startAnimation()
            }

            animator.startAnimation()
        } else {
            UIView.animate(withDuration: 0.1, animations: {
                self.boardView.alpha = 0
                self.boardView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }, completion: { _ in
                self.resetBoard()

                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: {
                    self.boardView.alpha = 1
                    self.boardView.transform = .identity
                }, completion: nil)
            })
        }
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