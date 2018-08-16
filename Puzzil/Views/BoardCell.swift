//
//  BoardCell.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-10.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardCell: UICollectionViewCell {
    var boardView: BoardView {
        return staticBoardView
    }

    private let staticBoardView = StaticBoardView(board: BoardStyle.original.board)
    let titleLabel = UILabel()
    var boardStyle: BoardStyle! {
        didSet {
            staticBoardView.staticBoard = boardStyle.board
            titleLabel.text = boardStyle.rawValue.capitalized
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        staticBoardView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = ColorTheme.selected.primaryTextOnBackground

        let boardLayoutGuide = UILayoutGuide()

        contentView.addSubview(staticBoardView)
        contentView.addSubview(titleLabel)
        contentView.addLayoutGuide(boardLayoutGuide)

        NSLayoutConstraint.activate([
            boardLayoutGuide.topAnchor.constraint(equalTo: contentView.topAnchor),
            boardLayoutGuide.heightAnchor.constraint(equalTo: contentView.widthAnchor),
            boardLayoutGuide.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            boardLayoutGuide.rightAnchor.constraint(equalTo: contentView.rightAnchor),

            staticBoardView.centerXAnchor.constraint(equalTo: boardLayoutGuide.centerXAnchor),
            staticBoardView.centerYAnchor.constraint(equalTo: boardLayoutGuide.centerYAnchor),
            staticBoardView.widthAnchor.constraint(lessThanOrEqualTo: boardLayoutGuide.widthAnchor),
            staticBoardView.heightAnchor.constraint(lessThanOrEqualTo: boardLayoutGuide.heightAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.firstBaselineAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        let optionalConstraints = [
            staticBoardView.widthAnchor.constraint(equalTo: boardLayoutGuide.widthAnchor),
            staticBoardView.heightAnchor.constraint(equalTo: boardLayoutGuide.widthAnchor),
        ]

        optionalConstraints.forEach { $0.priority = UILayoutPriority.defaultHigh }
        NSLayoutConstraint.activate(optionalConstraints)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
