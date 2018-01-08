//
//  TileView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-30.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class TileView: GradientView {
    var text = "" {
        didSet {
            labelView.text = text
        }
    }
    let labelView = UILabel()

    init() {
        super.init(from: .themeForegroundPink, to: .themeForegroundOrange)

        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.textAlignment = .center
        labelView.textColor = .white

        addSubview(labelView)

        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = min(32, frame.width, frame.height) / 2
        labelView.font = UIFont.systemFont(ofSize: frame.height / 2, weight: .bold)
    }
}
