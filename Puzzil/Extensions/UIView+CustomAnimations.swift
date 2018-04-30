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
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(rawValue: 0), animations: {
            views.forEach {
                $0.alpha = 0
                $0.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }
        }) { _ in
            reloadBlock()
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: {
                views.forEach {
                    $0.alpha = 1
                    $0.transform = .identity
                }
            }, completion: nil)
        }
    }
}
