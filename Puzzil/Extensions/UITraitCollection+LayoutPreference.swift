//
//  UITraitCollection+LayoutPreference.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-10-03.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

extension UITraitCollection {
    var prefersLandscapeLayout: Bool {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.regular, _), (.compact, .compact):
            return true
        default:
            return false
        }
    }
}
