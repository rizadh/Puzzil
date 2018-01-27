//
//  BoardViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-20.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardViewController: UIViewController, BoardViewDelegate {

    private let configuration: BoardConfiguration
    private let board: Board
    private let titleLabel = UILabel()
    private let boardView = BoardView()
    private lazy var startButton = RoundedButton("Start") { _ in self.startGame() }

    init(for configuration: BoardConfiguration) {
        self.configuration = configuration
        self.board = Board(from: configuration.matrix)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = configuration.name.capitalized
        titleLabel.textColor = .themeText
        titleLabel.font = {
            let baseFont = UIFont.systemFont(ofSize: 20, weight: .regular)
            if #available(iOS 11.0, *) {
                return UIFontMetrics(forTextStyle: .headline).scaledFont(for: baseFont)
            } else {
                return baseFont
            }
        }()
        view.addSubview(titleLabel)

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self
        boardView.isDynamic = false
        view.addSubview(boardView)

        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)

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
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),

            boardView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            boardView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            boardView.leftAnchor.constraint(greaterThanOrEqualTo: safeArea.leftAnchor, constant: 16),
            safeArea.rightAnchor.constraint(greaterThanOrEqualTo: boardView.rightAnchor, constant: 16),
            boardView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.7),
            boardView.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 16),

            startButton.leftAnchor.constraint(equalTo: safeArea.leftAnchor, constant: 16),
            safeArea.rightAnchor.constraint(equalTo: startButton.rightAnchor, constant: 16),
            startButton.topAnchor.constraint(greaterThanOrEqualTo: boardView.bottomAnchor, constant: 16),
            safeArea.bottomAnchor.constraint(equalTo: startButton.bottomAnchor),
            startButton.heightAnchor.constraint(equalToConstant: 60),
        ])

        NSLayoutConstraint.activate([
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
        ].map {
            $0.priority = .defaultHigh
            return $0
        })

        boardView.reloadTiles()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let alphaAnimationDuration = 0.1
        let scaleAnimationDuration = 0.25
        let dampingRatio: CGFloat = 1
        let alphaAnimations = {
            self.view.alpha = 1
        }
        let scaleAnimations = {
            self.boardView.transform = .identity
            self.titleLabel.transform = .identity
            self.startButton.transform = .identity
        }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: alphaAnimationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: scaleAnimationDuration, dampingRatio: dampingRatio, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: alphaAnimationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: scaleAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
        }
    }

    @objc private func startGame() {
        let notification = Notification(name: Notification.Name(rawValue: "com.rizadh.Puzzil.beginGame"), object: self, userInfo: ["configuration": configuration])

        let boardSelectorViewController = parent?.parent as! BoardSelectorViewController

        let animationDuration = 0.1
        let alphaAnimations = {
            self.view.alpha = 0
            boardSelectorViewController.view.subviews.forEach { $0.alpha = 0 }
        }
        let scaleAnimations = {
            self.boardView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            self.titleLabel.transform = CGAffineTransform(translationX: 0, y: -32)
            self.startButton.transform = CGAffineTransform(translationX: 0, y: 32)
            boardSelectorViewController.headerView.transform = CGAffineTransform(translationX: 0, y: -32)
            boardSelectorViewController.pageControl.transform = CGAffineTransform(translationX: 0, y: 32)
        }

        let completion: (Any) -> Void = { _ in NotificationCenter.default.post(notification) }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: animationDuration, curve: .linear, animations: scaleAnimations).startAnimation()
            let animator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeIn, animations: alphaAnimations)
            animator.addCompletion(completion)
            animator.startAnimation()
        } else {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveLinear, animations: scaleAnimations, completion: nil)
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseIn, animations: alphaAnimations, completion: completion)
        }
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
        return
    }
}
