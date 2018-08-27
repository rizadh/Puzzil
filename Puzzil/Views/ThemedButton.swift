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

    override var isHighlighted: Bool {
        didSet {
            isHighlighted ? activateHighlight() : deactivateHighlight()
        }
    }

    override var isEnabled: Bool {
        didSet {
            isEnabled ? setEnabledTintColor() : setDisabledTintColor()
        }
    }

    convenience init() {
        self.init(type: .custom)

        layer.cornerRadius = 16
        highlightLayer.cornerRadius = 16
        highlightLayer.opacity = 0
        let baseColor: UIColor
        switch ColorTheme.selected {
        case .light:
            baseColor = .black
        case .dark:
            baseColor = .white
        }
        highlightLayer.backgroundColor = baseColor.withAlphaComponent(0.2).cgColor
        layer.addSublayer(highlightLayer)
        backgroundColor = ColorTheme.selected.primary
        setEnabledTintColor()
        setTitleColor(ColorTheme.selected.primaryTextOnPrimary, for: .normal)
        setTitleColor(ColorTheme.selected.primaryTextOnPrimary.withAlphaComponent(0.5), for: .disabled)
        titleLabel!.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false
    }

    private func setEnabledTintColor() {
        UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            self.tintColor = ColorTheme.selected.primaryTextOnPrimary
        }.startAnimation()
    }

    private func setDisabledTintColor() {
        UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            self.tintColor = ColorTheme.selected.primaryTextOnPrimary.withAlphaComponent(0.5)
        }.startAnimation()
    }

    private func activateHighlight() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        highlightLayer.opacity = 1
        CATransaction.commit()
    }

    private func deactivateHighlight() {
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
