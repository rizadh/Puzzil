//
//  BoardSelectionViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-20.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardSelectionViewController: UIViewController {
    // MARK: - Subviews

    let boardStyle: BoardStyle
    let boardView = BoardView()

    // MARK: - Controller Dependencies

    var bestTimesController: BestTimesController!

    // MARK: - Constructors

    init(boardStyle: BoardStyle) {
        self.boardStyle = boardStyle

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Method Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(boardWasTapped))
        boardView.addGestureRecognizer(tapGestureRecognizer)

        let pressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(boardWasPressed))
        pressGestureRecognizer.minimumPressDuration = 0
        pressGestureRecognizer.delegate = self
        boardView.addGestureRecognizer(pressGestureRecognizer)

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.isDynamic = false
        boardView.delegate = self

        view.addSubview(boardView)

        let boardScale: CGFloat = 0.7

        NSLayoutConstraint.activate([
            boardView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            boardView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: boardScale),
            boardView.leftAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16),
            boardView.rightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16),

            boardView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            boardView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: boardScale),
            boardView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            boardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ] + [
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: boardScale),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: boardScale),
        ].map {
            $0.priority = .defaultLow
            return $0
        })

        boardView.reloadBoard()
    }

    // MARK: - Event Handlers

    @objc private func boardWasTapped(_ sender: UITapGestureRecognizer) {
        let gameViewController = GameViewController(boardStyle: boardStyle)
        gameViewController.transitioningDelegate = parent?.parent as! MainViewController
        gameViewController.bestTimesController = bestTimesController
        present(gameViewController, animated: true)
    }

    @objc private func boardWasPressed(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                               self.boardView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            })
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                               self.boardView.transform = .identity
            })
        default:
            break
        }
    }
}

// MARK: - BoardViewDelegate

extension BoardSelectionViewController: BoardViewDelegate {
    func newBoard(for boardView: BoardView) -> Board {
        return boardStyle.board
    }

    func boardDidChange(_ boardView: BoardView) {
        fatalError("Static board cannot change")
    }

    func progressDidChange(_ boardView: BoardView) {
        fatalError("Static board cannot change")
    }
}

// MARK: - UIGestureRecognizerDelegate

extension BoardSelectionViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
