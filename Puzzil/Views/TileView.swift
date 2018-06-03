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
    private let darkeningLayer = CALayer()

    init() {
        super.init(frame: .zero)

        backgroundColor = .themeTile

        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        darkeningLayer.isHidden = false
        CATransaction.commit()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.25)
        darkeningLayer.isHidden = true
        CATransaction.commit()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.25)
        darkeningLayer.isHidden = true
        CATransaction.commit()
    }

    private func setupSubviews() {
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.textAlignment = .center
        labelView.textColor = .themeTileText

        darkeningLayer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor
        darkeningLayer.isHidden = true

        layer.masksToBounds = true

        addSubview(labelView)
        layer.addSublayer(darkeningLayer)

        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = min(2 * TileView.maxCornerRadius, frame.width, frame.height) / 2
        darkeningLayer.frame = layer.bounds
        labelView.font = UIFont.systemFont(ofSize: frame.height / 2, weight: .bold)
    }
}
