//
//  RoundedButton.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-03.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

extension UIButton {
    static func createThemedButton() -> UIButton {
        let button = UIButton()

        button.layer.cornerRadius = 16
        button.backgroundColor = .themePrimary
        button.setTitleColor(.themePrimaryTextOnPrimary, for: .normal)
        button.setTitleColor(UIColor.themePrimaryTextOnPrimary.withAlphaComponent(0.5), for: .disabled)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        button.titleLabel!.allowsDefaultTighteningForTruncation = true

        button.addTarget(button, action: #selector(buttonWasPressed), for: [.touchDown, .touchDragEnter])
        button.addTarget(button, action: #selector(buttonWasReleased), for: [.touchUpInside, .touchCancel, .touchDragExit])

        return button
    }

    @objc private func buttonWasPressed() {
        UIView.animate(
            withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0,
            options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        })
    }

    @objc private func buttonWasReleased() {
        UIView.animate(
            withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0,
            options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                self.transform = .identity
        })
    }
}
