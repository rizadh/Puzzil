//
//  BoardCell.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-10.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import os
import UIKit

class BoardCell: UICollectionViewCell {
    private static var cachedSnapshots = [BoardStyle: (view: UIView, size: CGSize)]()

    private let titleLabel = UILabel()
    private let boardLayoutGuide = UILayoutGuide()
    private(set) var lastSnapshotView: UIView?
    var boardStyle: BoardStyle! {
        didSet {
            guard boardStyle != oldValue else { return }
            layoutSnapshotView()
            titleLabel.text = boardStyle.rawValue.capitalized
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = ColorTheme.selected.primaryTextOnBackground

        contentView.addSubview(titleLabel)
        contentView.addLayoutGuide(boardLayoutGuide)

        NSLayoutConstraint.activate([
            boardLayoutGuide.topAnchor.constraint(equalTo: contentView.topAnchor),
            boardLayoutGuide.heightAnchor.constraint(equalTo: contentView.widthAnchor),
            boardLayoutGuide.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            boardLayoutGuide.rightAnchor.constraint(equalTo: contentView.rightAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.firstBaselineAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSnapshotView() {
        let (snapshotView, snapshotSize) = BoardCell.fetchSnapshot(for: boardStyle)
        snapshotView.translatesAutoresizingMaskIntoConstraints = false
        if lastSnapshotView.flatMap(contentView.subviews.contains) ?? false {
            lastSnapshotView?.removeFromSuperview()
        }
        lastSnapshotView = snapshotView
        contentView.addSubview(snapshotView)

        NSLayoutConstraint.activate([
            snapshotView.centerXAnchor.constraint(equalTo: boardLayoutGuide.centerXAnchor),
            snapshotView.centerYAnchor.constraint(equalTo: boardLayoutGuide.centerYAnchor),
            snapshotView.widthAnchor.constraint(equalToConstant: snapshotSize.width),
            snapshotView.heightAnchor.constraint(equalToConstant: snapshotSize.height),
        ])
    }

    static func flushCache() {
        cachedSnapshots.removeAll()
    }

    static func generateSnapshots() {
        BoardStyle.allCases.forEach {
            _ = generateSnapshot(for: $0)
        }
    }

    private static func fetchSnapshot(for style: BoardStyle) -> (view: UIView, size: CGSize) {
        if let cachedSnapshot = cachedSnapshots[style] {
            return cachedSnapshot
        } else {
            os_log("Cached board snapshot not available. Generating snapshot on-demand.")
            return generateSnapshot(for: style)
        }
    }

    private static func generateSnapshot(for style: BoardStyle) -> (view: UIView, size: CGSize) {
        let boardView = StaticBoardView(board: style.board)
        boardView.translatesAutoresizingMaskIntoConstraints = false
        let optionalConstraints = [
            boardView.widthAnchor.constraint(equalToConstant: 180),
            boardView.heightAnchor.constraint(equalToConstant: 180),
        ]
        optionalConstraints.forEach { $0.priority = .defaultLow }
        NSLayoutConstraint.activate(optionalConstraints)
        boardView.layoutIfNeeded()

        let snapshot = boardView.snapshotView(afterScreenUpdates: true)!

        BoardCell.cachedSnapshots[style] = (snapshot, boardView.bounds.size)

        return (snapshot, boardView.bounds.size)
    }
}
