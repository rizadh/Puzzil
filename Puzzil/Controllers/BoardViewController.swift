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
    private let boardView = BoardView()
    private let label = UILabel()
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

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self
        boardView.isDynamic = false
        view.addSubview(boardView)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = configuration.name.capitalized
        label.font = {
            if #available(iOS 11.0, *) {
                return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.boldSystemFont(ofSize: 24))
            } else {
                return UIFont.boldSystemFont(ofSize: 24)
            }
        }()
        view.addSubview(label)

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

        let labelGuide = UILayoutGuide()
        view.addLayoutGuide(labelGuide)

        NSLayoutConstraint.activate([
            labelGuide.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            boardView.topAnchor.constraint(equalTo: labelGuide.bottomAnchor, constant: 16),
            labelGuide.heightAnchor.constraint(greaterThanOrEqualToConstant: label.intrinsicContentSize.height),

            label.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: labelGuide.centerYAnchor),

            boardView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            boardView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            boardView.leftAnchor.constraint(greaterThanOrEqualTo: safeArea.leftAnchor, constant: 16),
            safeArea.rightAnchor.constraint(greaterThanOrEqualTo: boardView.rightAnchor, constant: 16),
            boardView.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: 16),

            startButton.leftAnchor.constraint(equalTo: boardView.leftAnchor),
            startButton.rightAnchor.constraint(equalTo: boardView.rightAnchor),
            startButton.topAnchor.constraint(greaterThanOrEqualTo: boardView.bottomAnchor, constant: 16),
            safeArea.bottomAnchor.constraint(equalTo: startButton.bottomAnchor),
            startButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
        ])

        NSLayoutConstraint.activate([
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor),
            startButton.heightAnchor.constraint(equalToConstant: 60)
        ].map {
            $0.priority = .defaultHigh
            return $0
        })

        boardView.reloadTiles()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let animationDuration = 0.25
        let dampingRatio: CGFloat = 0.5
        let alphaAnimations = {
           self.view.alpha = 1
        }
        let scaleAnimations = {
            self.boardView.transform = .identity
        }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: animationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: animationDuration, dampingRatio: dampingRatio, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
        }
    }

    @objc private func startGame() {
        let notification = Notification(name: Notification.Name(rawValue: "com.rizadh.Puzzil.beginGame"), object: self, userInfo: ["configuration": configuration])

        let animationDuration = 0.1
        let alphaAnimations = {
            self.view.alpha = 0
        }

        let scaleAnimations = {
            self.boardView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }

        let completion: (Any) -> Void = { _ in
            NotificationCenter.default.post(notification)
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

    func updateGradient() {
        boardView.updateGradient(usingPresentationLayer: false)
        startButton.updateGradient(usingPresentationLayer: false)
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
