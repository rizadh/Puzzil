//
//  UIColor+Random.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-25.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

extension UIColor {
    static func randomHue() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }

    static func randomColor() -> UIColor {
        return UIColor(
            hue: randomHue(),
            saturation: 0.7,
            brightness: 1,
            alpha: 1
        )
    }
}
