//
//  UIView+CustomAnimations.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-28.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

extension UIView {
    static func springReload(views: [UIView], reloadBlock: @escaping () -> Void) {
        let initialAnimationDuration = 0.1
        let initialAlphaAnimations = {
            views.forEach { $0.alpha = 0 }
        }
        let initialScaleAnimations = {
            views.forEach { $0.transform = CGAffineTransform(scaleX: 0.5, y: 0.5) }
        }

        let finalAlphaAnimationDuration = 0.1
        let finalScaleAnimationDuration = 0.25
        let finalAlphaAnimations = {
            views.forEach { $0.alpha = 1 }
        }
        let finalScaleAnimations = {
            views.forEach { $0.transform = .identity }
        }

        let dampingRatio: CGFloat = 0.5

        let triggerFinalAnimation: () -> Void

        if #available(iOS 10.0, *) {
            triggerFinalAnimation = {
                UIViewPropertyAnimator(duration: finalAlphaAnimationDuration, curve: .linear, animations: finalAlphaAnimations).startAnimation()
                UIViewPropertyAnimator(duration: finalScaleAnimationDuration, dampingRatio: dampingRatio, animations: finalScaleAnimations).startAnimation()
            }
        } else {
            triggerFinalAnimation = {
                UIView.animate(withDuration: finalAlphaAnimationDuration, delay: 0, options: .curveLinear, animations: finalAlphaAnimations, completion: nil)
                UIView.animate(withDuration: finalScaleAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: finalScaleAnimations, completion: nil)
            }
        }

        let completion: (Any) -> Void = { _ in
            reloadBlock()
            triggerFinalAnimation()
        }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: initialAnimationDuration, curve: .linear, animations: initialAlphaAnimations).startAnimation()
            let animator = UIViewPropertyAnimator(duration: initialAnimationDuration, curve: .easeIn, animations: initialScaleAnimations)
            animator.addCompletion(completion)
            animator.startAnimation()
        } else {
            UIView.animate(withDuration: initialAnimationDuration, delay: 0, options: .curveLinear, animations: initialAlphaAnimations, completion: nil)
            UIView.animate(withDuration: initialAnimationDuration, delay: 0, options: .curveEaseIn, animations: initialScaleAnimations, completion: completion)
        }
    }
}
