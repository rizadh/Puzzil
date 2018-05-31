//
//  StaticBoardViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-20.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class StaticBoardViewController: UIViewController {

    // MARK: - Subviews

    let boardStyle: BoardStyle
    let boardView = BoardView()

    // MARK: - Board Status

    private let boardWaitingQueue: DispatchQueue
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    private var boardIsReady = true {
        didSet {
            if boardIsReady { hideLoadingIndicator() }
            else { showLoadingIndicator() }
        }
    }

    // MARK: Application Globals

    private let boardScrambler = (UIApplication.shared.delegate as! AppDelegate).boardScrambler

    // MARK: - Constructors

    init(boardStyle: BoardStyle) {
        self.boardStyle = boardStyle
        boardWaitingQueue = DispatchQueue(label: "com.rizadh.Puzzil.StaticBoardViewController.boardWaitingQueue.\(boardStyle)", qos: .background)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Method Overrides

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        waitForBoard()
    }

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

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .themeTile

        view.addSubview(boardView)
        view.addSubview(loadingIndicator)

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
            boardView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            boardView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.7),
            boardView.leftAnchor.constraint(greaterThanOrEqualTo: safeArea.leftAnchor, constant: 16),
            boardView.rightAnchor.constraint(lessThanOrEqualTo: safeArea.rightAnchor, constant: -16),

            boardView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            boardView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.7),
            boardView.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: 16),
            boardView.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -16),

            loadingIndicator.centerXAnchor.constraint(equalTo: boardView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: boardView.centerYAnchor),
        ] + [
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
        ].map {
            $0.priority = .defaultLow
            return $0
        })

        boardView.reloadBoard()
    }

    // MARK: - Private Methods

    private func showLoadingIndicator() {
        boardView.isHidden = true
        loadingIndicator.startAnimating()
    }

    private func hideLoadingIndicator() {
        boardView.isHidden = false
        loadingIndicator.stopAnimating()
    }

    private func waitForBoard() {
        boardWaitingQueue.async {
            DispatchQueue.main.async {
                self.boardIsReady = false
            }
            self.boardScrambler.waitForBoard(style: self.boardStyle)
            DispatchQueue.main.async {
                self.boardIsReady = true
            }
        }
    }

    // MARK: - Event Handlers

    @objc private func boardWasTapped(_ sender: UITapGestureRecognizer) {
        guard boardIsReady else { return }

        let gameViewController = GameViewController(boardStyle: boardStyle, difficulty: 0.5)
        gameViewController.transitioningDelegate = parent?.parent as! BoardSelectorViewController
        present(gameViewController, animated: true)
    }

    @objc private func boardWasPressed(_ sender: UILongPressGestureRecognizer) {
        print(sender.state.rawValue)
        switch sender.state {
        case .began:
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                               self.boardView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            })
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                               self.boardView.transform = .identity
            })
        default:
            break
        }
    }
}

// MARK: - BoardViewDelegate

extension StaticBoardViewController: BoardViewDelegate {
    func newBoard(for boardView: BoardView) -> Board {
        return boardStyle.board
    }

    func boardDidChange(_ boardView: BoardView) {
        fatalError("Static board cannot change")
    }
}

// MARK: - UIGestureRecognizerDelegate

extension StaticBoardViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
