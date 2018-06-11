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
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        highlightLayer.isHidden = false
        CATransaction.commit()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveLinear], animations: {
            self.highlightLayer.isHidden = true
        })
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveLinear], animations: {
            self.highlightLayer.isHidden = true
        })
    }

    private func setupSubviews() {
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.textAlignment = .center
        labelView.textColor = ColorTheme.selected.primaryTextOnPrimary

        highlightLayer.isHidden = true

        switch ColorTheme.selected {
        case .light:
            highlightLayer.backgroundColor = UIColor.black.withAlphaComponent(0.2).cgColor
        case .dark:
            highlightLayer.backgroundColor = UIColor.white.withAlphaComponent(0.2).cgColor
        }

        layer.masksToBounds = true

        addSubview(labelView)
        layer.addSublayer(highlightLayer)

        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = min(2 * TileView.maxCornerRadius, frame.width, frame.height) / 2
        highlightLayer.frame = layer.bounds
        labelView.font = UIFont.systemFont(ofSize: frame.height / 2, weight: .bold)
    }
}
