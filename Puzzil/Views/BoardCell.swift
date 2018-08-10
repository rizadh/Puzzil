//
//  BoardCell.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-10.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardCell: UICollectionViewCell {
    private let boardView = StaticBoardView(board: BoardStyle.original.board)
    private let titleLabel = UILabel()
    var boardStyle = BoardStyle.original {
        didSet {
            boardView.staticBoard = boardStyle.board
            titleLabel.text = boardStyle.rawValue.capitalized
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        boardView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)

        let boardLayoutGuide = UILayoutGuide()

        contentView.addSubview(boardView)
        contentView.addSubview(titleLabel)
        contentView.addLayoutGuide(boardLayoutGuide)

        NSLayoutConstraint.activate([
            boardLayoutGuide.topAnchor.constraint(equalTo: contentView.topAnchor),
            boardLayoutGuide.heightAnchor.constraint(equalTo: contentView.widthAnchor),
            boardLayoutGuide.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            boardLayoutGuide.rightAnchor.constraint(equalTo: contentView.rightAnchor),

            boardView.centerXAnchor.constraint(equalTo: boardLayoutGuide.centerXAnchor),
            boardView.centerYAnchor.constraint(equalTo: boardLayoutGuide.centerYAnchor),
            boardView.widthAnchor.constraint(lessThanOrEqualTo: boardLayoutGuide.widthAnchor),
            boardView.heightAnchor.constraint(lessThanOrEqualTo: boardLayoutGuide.heightAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.firstBaselineAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        let optionalConstraints = [
            boardView.widthAnchor.constraint(equalTo: boardLayoutGuide.widthAnchor),
            boardView.heightAnchor.constraint(equalTo: boardLayoutGuide.widthAnchor),
        ]

        optionalConstraints.forEach { $0.priority = UILayoutPriority.defaultHigh }
        NSLayoutConstraint.activate(optionalConstraints)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
