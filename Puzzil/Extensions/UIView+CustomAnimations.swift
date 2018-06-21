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

    static func animatedSwap(outgoingView: UIView, incomingView: UIView, midCompletion: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.125, delay: 0, options: [.curveEaseIn], animations: {
            outgoingView.transform = .zero
        }) { _ in
            outgoingView.isHidden = true
            midCompletion?()
        }

        incomingView.isHidden = false
        incomingView.transform = .zero
        UIView.animate(withDuration: 0.25, delay: 0.125, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
            incomingView.transform = .identity
        }) { _ in completion?() }
    }

    func applyMotionEffect(distance: CGFloat) {
        let xMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.x", type: .tiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = -distance
        xMotion.maximumRelativeValue = distance

        let yMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.y", type: .tiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = -distance
        yMotion.maximumRelativeValue = distance

        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [xMotion, yMotion]

        addMotionEffect(motionEffectGroup)
    }
}

extension CGAffineTransform {
    static let zero = CGAffineTransform(scaleX: 1e-5, y: 1e-5)
}
