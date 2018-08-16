//
//  ThemedButton.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-06-22.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class ThemedButton: UIButton {
    private let highlightLayer = CALayer()

    convenience init() {
        self.init(type: .custom)

        layer.cornerRadius = 16
        highlightLayer.cornerRadius = 16
        highlightLayer.opacity = 0
        switch ColorTheme.selected {
        case .light:
            highlightLayer.backgroundColor = UIColor.black.withAlphaComponent(0.2).cgColor
        case .dark:
            highlightLayer.backgroundColor = UIColor.white.withAlphaComponent(0.2).cgColor
        }
        layer.addSublayer(highlightLayer)
        backgroundColor = ColorTheme.selected.primary
        tintColor = ColorTheme.selected.primaryTextOnPrimary
        setTitleColor(ColorTheme.selected.primaryTextOnPrimary, for: .normal)
        titleLabel!.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false

        addTarget(self, action: #selector(buttonWasPressed), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(buttonWasReleased), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    @objc private func buttonWasPressed() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        highlightLayer.opacity = 1
        CATransaction.commit()
    }

    @objc private func buttonWasReleased() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.25)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear))
        highlightLayer.opacity = 0
        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        highlightLayer.frame = layer.bounds
    }
}
