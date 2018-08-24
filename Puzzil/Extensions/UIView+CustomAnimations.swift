//
//  UIView+CustomAnimations.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-28.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

extension UIView {
    func springReload(reloadBlock: ((Bool) -> Void)? = nil, completion: ((Bool) -> Void)? = nil) {
        let exitDuration = 0.125
        let popDuration = 0.25

        UIView.animate(withDuration: exitDuration, delay: 0, options: [.beginFromCurrentState], animations: {
            self.transform = .zero
        }, completion: reloadBlock)

        UIView.animate(withDuration: popDuration, delay: exitDuration, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 1, options: [.beginFromCurrentState],
                       animations: { self.transform = .identity },
                       completion: completion)
    }

    static func animatedSwap(outgoingView: UIView, incomingView: UIView, completion completionOrNil: ((UIViewAnimatingPosition) -> Void)? = nil) {
        let outgoingDuration: TimeInterval = 0.125
        let incomingDuration: TimeInterval = 0.25

        let outgoingAnimator = UIViewPropertyAnimator(duration: outgoingDuration, curve: .easeIn) {
            outgoingView.transform = .zero
        }
        outgoingAnimator.addCompletion { _ in
            outgoingView.isHidden = true
        }
        outgoingAnimator.startAnimation()

        incomingView.isHidden = false
        incomingView.transform = .zero
        let incomingAnimator = UIViewPropertyAnimator(duration: incomingDuration, dampingRatio: 0.8) {
            incomingView.transform = .identity
        }
        if let completion = completionOrNil {
            incomingAnimator.addCompletion(completion)
        }
        incomingAnimator.startAnimation(afterDelay: outgoingDuration)
    }

    func shake() {
        let angle: CGFloat = .pi / 32

        UIViewPropertyAnimator(duration: 0.25, curve: .easeOut) {
            UIView.animateKeyframes(withDuration: 0, delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.125, animations: {
                    self.transform = CGAffineTransform(rotationAngle: angle)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.125, relativeDuration: 0.25, animations: {
                    self.transform = CGAffineTransform(rotationAngle: -angle)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.375, relativeDuration: 0.25, animations: {
                    self.transform = CGAffineTransform(rotationAngle: angle)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.625, relativeDuration: 0.25, animations: {
                    self.transform = CGAffineTransform(rotationAngle: -angle)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.875, relativeDuration: 0.125, animations: {
                    self.transform = .identity
                })
            })
        }.startAnimation()
    }
}

extension CGAffineTransform {
    static let zero = CGAffineTransform(scaleX: 1e-5, y: 1e-5)
}
