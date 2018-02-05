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

        button.addTarget(button, action: #selector(animateDepression), for: .touchDown)
        button.addTarget(button, action: #selector(animateRelease), for: [.touchUpInside, .touchCancel, .touchDragExit])

        return button
    }

    @objc private func animateDepression() {
        let alphaAnimationDuration = 0.1
        let scaleAnimationDuration = 0.25
        let dampingRatio: CGFloat = 1
        let scaleAnimations = { self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }
        let alphaAnimations = { self.titleLabel!.alpha = 0.5 }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: alphaAnimationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: scaleAnimationDuration, dampingRatio: dampingRatio, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: alphaAnimationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: scaleAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
        }
    }

    @objc private func animateRelease() {
        let alphaAnimationDuration = 0.1
        let scaleAnimationDuration = 0.25
        let dampingRatio: CGFloat = 0.5
        let scaleAnimations = { self.transform = .identity }
        let alphaAnimations = { self.titleLabel!.alpha = 1 }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: alphaAnimationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: scaleAnimationDuration, dampingRatio: dampingRatio, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: alphaAnimationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: scaleAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
        }
    }
}
