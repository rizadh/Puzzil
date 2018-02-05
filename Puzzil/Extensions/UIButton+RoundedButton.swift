//
//  RoundedButton.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-03.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

extension UIButton {
    static func themedButton() -> UIButton {
        let button = UIButton()

        button.layer.cornerRadius = 16
        button.backgroundColor = .themeButton
        button.setTitleColor(.themeButtonText, for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        button.titleLabel!.allowsDefaultTighteningForTruncation = true

        button.addTarget(button, action: #selector(buttonWasPressed), for: [.touchDown, .touchDragEnter])
        button.addTarget(button, action: #selector(buttonWasReleased), for: [.touchUpInside, .touchCancel, .touchDragExit])

        return button
    }

    @objc private func buttonWasPressed() {
        self.titleLabel!.alpha = 0.5
    }

    @objc private func buttonWasReleased() {
        let animationDuration = 0.1
        let animations = { self.titleLabel!.alpha = 1 }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: animationDuration, curve: .linear, animations: animations).startAnimation()
        } else {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveLinear, animations: animations, completion: nil)
        }
    }
}
