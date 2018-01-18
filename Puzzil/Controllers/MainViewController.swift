//
//  MainViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-13.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, BoardViewDelegate, UIScrollViewDelegate {
    override var prefersStatusBarHidden: Bool {
        return true
    }

    private var boards = [BoardView: Board]()
    private var boardIndex = 0
    private let boardConfigurations = [
        BoardConfiguration(name: "regular", matrix: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, nil],
        ]),
        BoardConfiguration(name: "telephone", matrix: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
            [nil, 0, nil],
        ]),
    ]

    private var playButton: RoundedButton!
    private var boardStackView: UIStackView!
    private var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let gradientView = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)
        gradientView.frame = view.bounds
        gradientView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(gradientView)

        let boardStackView = UIStackView()
        boardStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(boardStackView)
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)

        playButton = RoundedButton("Play") { [unowned self] _ in self.beginSelectedBoard() }
        playButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playButton)

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

        for configuration in boardConfigurations {
            let containerView = UIView()
            let board = Board(from: configuration.matrix)
            let boardView = BoardView()
            boards[boardView] = board
            boardView.translatesAutoresizingMaskIntoConstraints = false
            boardView.isDynamic = false
            boardView.delegate = self
            boardView.reloadTiles()

            boardStackView.addArrangedSubview(containerView)
            containerView.addSubview(boardView)

            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalTo: safeArea.widthAnchor),
                containerView.heightAnchor.constraint(equalTo: safeArea.heightAnchor),

                boardView.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor, constant: 16),
                boardView.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor, constant: -16),
                boardView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor, constant: 16),
                boardView.bottomAnchor.constraint(lessThanOrEqualTo: playButton.topAnchor, constant: -16),
                boardView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                boardView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            ])

            [
                boardView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
                boardView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            ].forEach {
                $0.priority = .defaultHigh
                $0.isActive = true
            }
        }

        let buttonHeightConstraint = playButton.heightAnchor.constraint(equalToConstant: 60)
        buttonHeightConstraint.priority = .defaultHigh
        buttonHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            scrollView.leftAnchor.constraint(equalTo: safeArea.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: safeArea.rightAnchor),

            boardStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            boardStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            boardStackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            boardStackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),

            playButton.leftAnchor.constraint(equalTo: safeArea.leftAnchor, constant: 16),
            playButton.rightAnchor.constraint(equalTo: safeArea.rightAnchor, constant: -16),
            playButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
            playButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        let animationDuration = 0.25
        let alphaAnimations = {
            self.scrollView.alpha = 1
            self.playButton.alpha = 1
        }
        let scaleAnimations = {
            self.scrollView.transform = .identity
        }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: animationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: animationDuration, dampingRatio: 1, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
        }

        updateGradients()
    }

    override func viewDidLayoutSubviews() {
        updateGradients()
    }

    private func updateGradients() {
        boards.keys.forEach { $0.updateGradient(false) }
        playButton.updateGradient(false)
    }

    private func beginSelectedBoard() {
        let selectedConfiguration = self.boardConfigurations[self.boardIndex]
        let board = Board(from: selectedConfiguration.matrix)
        let boardViewController = BoardViewController(board: board, difficulty: 0.5)

        let animationDuration = 0.1
        let alphaAnimations = {
            self.scrollView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }

        let scaleAnimations = {
            self.scrollView.alpha = 0
            self.playButton.alpha = 0
        }

        let completion: (Any) -> Void = { _ in
            self.present(boardViewController, animated: false, completion: nil)
        }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: animationDuration, curve: .linear, animations: scaleAnimations).startAnimation()
            let shrinkingAnimator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeIn, animations: alphaAnimations)
            shrinkingAnimator.addCompletion(completion)
            shrinkingAnimator.startAnimation()
        } else {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveLinear, animations: scaleAnimations, completion: nil)
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseIn, animations: alphaAnimations, completion: completion)
        }
    }

    func numberOfRows(in boardView: BoardView) -> Int {
        return boards[boardView]!.rows
    }

    func numberOfColumns(in boardView: BoardView) -> Int {
        return boards[boardView]!.columns
    }

    func boardView(_ boardView: BoardView, tileTextAt position: TilePosition) -> String? {
        return boards[boardView]!.tileText(at: position)
    }

    func boardView(_ boardView: BoardView, canPerform moveOperation: TileMoveOperation) -> Bool? {
        return boards[boardView]!.canPerform(moveOperation)
    }

    func boardView(_ boardView: BoardView, didPerform moveOperation: TileMoveOperation) {
        boards[boardView]!.perform(moveOperation)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        boards.keys.forEach { $0.updateGradient(false) }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        boardIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
    }
}

private struct BoardConfiguration {
    let name: String
    let matrix: [[CustomStringConvertible?]]
}
