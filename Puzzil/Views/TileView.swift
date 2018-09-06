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
    private let highlightLayer = CALayer()

    init() {
        super.init(frame: .zero)

        backgroundColor = ColorTheme.selected.primary

        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        activateHighlight()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        deactivateHighlight()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        deactivateHighlight()
    }

    private func activateHighlight() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        highlightLayer.opacity = 1
        CATransaction.commit()
    }

    private func deactivateHighlight() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        highlightLayer.opacity = 0
        CATransaction.commit()
    }

    private func setupSubviews() {
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.textAlignment = .center
        labelView.textColor = ColorTheme.selected.primaryTextOnPrimary

        highlightLayer.opacity = 0

        switch ColorTheme.selected {
        case .light:
            highlightLayer.backgroundColor = UIColor.black.withAlphaComponent(0.2).cgColor
        case .dark:
            highlightLayer.backgroundColor = UIColor.white.withAlphaComponent(0.2).cgColor
        }

        addSubview(labelView)
        layer.addSublayer(highlightLayer)

        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadius = min(2 * TileView.maxCornerRadius, frame.width, frame.height) / 2
        layer.cornerRadius = cornerRadius
        highlightLayer.cornerRadius = cornerRadius
        highlightLayer.frame = layer.bounds
        let fontSize = min(frame.height / 2, 60)
        labelView.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
    }
}
