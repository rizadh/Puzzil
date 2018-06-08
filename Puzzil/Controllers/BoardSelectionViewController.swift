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

    // MARK: - Board Status

    private lazy var boardWaitingQueue = DispatchQueue(label: "com.rizadh.Puzzil.StaticBoardViewController.boardWaitingQueue.\(boardStyle)", qos: .background)
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    private var boardIsReady = true {
        didSet {
            if boardIsReady { hideLoadingIndicator() }
            else { showLoadingIndicator() }
        }
    }

    // MARK: - Controller Dependencies

    var bestTimesController: BestTimesController!
    var boardScramblingController: BoardScramblingController!

    // MARK: - Constructors

    init(boardStyle: BoardStyle) {
        self.boardStyle = boardStyle

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
        loadingIndicator.color = ColorTheme.selected.primary

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
        self.boardIsReady = false
        boardWaitingQueue.async {
            self.boardScramblingController.waitForBoard(style: self.boardStyle)
            DispatchQueue.main.async {
                self.boardIsReady = true
            }
        }
    }

    // MARK: - Event Handlers

    @objc private func boardWasTapped(_ sender: UITapGestureRecognizer) {
        guard boardIsReady else { return }

        let gameViewController = GameViewController(boardStyle: boardStyle)
        gameViewController.transitioningDelegate = parent?.parent as! MainViewController
        gameViewController.boardScramblingController = boardScramblingController
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
}

// MARK: - UIGestureRecognizerDelegate

extension BoardSelectionViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
