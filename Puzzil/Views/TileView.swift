//
//  TileView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-30.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class TileView: UIView {

    private static let maxCornerRadius: CGFloat = 16

    var text = "" {
        didSet {
            labelView.text = text
        }
    }
    private let labelView = UILabel()

    init() {
        super.init(frame: .zero)

        backgroundColor = .themeTile

        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.textAlignment = .center
        labelView.textColor = .themeTileText

        addSubview(labelView)

        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = min(2 * TileView.maxCornerRadius, frame.width, frame.height) / 2
        labelView.font = UIFont.systemFont(ofSize: frame.height / 2, weight: .bold)
    }
}
