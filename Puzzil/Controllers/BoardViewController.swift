//
//  BoardViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-20.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardViewController: UIViewController, BoardViewDelegate {
    let configuration: BoardConfiguration
    let boardView = BoardView()
    private let board: Board

    // MARK: - Constructors

    init(for configuration: BoardConfiguration) {
        self.configuration = configuration
        board = Board(from: configuration.matrix)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Method Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.delegate = self
        view.addSubview(boardView)

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
            safeArea.rightAnchor.constraint(greaterThanOrEqualTo: boardView.rightAnchor, constant: 16),

            boardView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            boardView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.7),
            boardView.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: 16),
            safeArea.bottomAnchor.constraint(greaterThanOrEqualTo: boardView.bottomAnchor, constant: 16),
        ] + [
            boardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            boardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
        ].map {
            $0.priority = .defaultLow
            return $0
        })

        boardView.reloadTiles()
    }

    // MARK: - BoardViewDelegate Methods

    func numberOfRows(in boardView: BoardView) -> Int {
        return board.rows
    }

    func numberOfColumns(in boardView: BoardView) -> Int {
        return board.columns
    }

    func boardIsDynamic(_ boardView: BoardView) -> Bool {
        return false
    }

    func boardView(_ boardView: BoardView, tileTextAt position: TilePosition) -> String? {
        return board.tileText(at: position)
    }

    func boardView(_ boardView: BoardView, canPerform moveOperation: TileMoveOperation) -> Bool? {
        fatalError("Cannot perform move operation")
    }

    func boardView(_ boardView: BoardView, didStart moveOperation: TileMoveOperation) {
        fatalError("Cannot start move operation")
    }

    func boardView(_ boardView: BoardView, didCancel moveOperation: TileMoveOperation) {
        fatalError("Cannot cancel move operation")
    }

    func boardView(_ boardView: BoardView, didComplete moveOperation: TileMoveOperation) {
        fatalError("Cannot complete move operation")
    }
}
