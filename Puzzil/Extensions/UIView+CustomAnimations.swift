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

        UIView.animate(withDuration: popDuration, delay: exitDuration, usingSpringWithDamping: 1,
                       initialSpringVelocity: 1, options: [.beginFromCurrentState],
                       animations: { self.transform = .identity },
                       completion: completion)
    }
}

extension CGAffineTransform {
    static let zero = CGAffineTransform(scaleX: 1e-5, y: 1e-5)
}
