//
//  StaticBoardViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-20.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class StaticBoardViewController: UIViewController {
    let boardStyle: BoardStyle
    let boardView = BoardView()
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var isReady = true {
        didSet {
            if isReady { hideLoadingIndicator() }
            else { showLoadingIndicator() }
        }
    }

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
