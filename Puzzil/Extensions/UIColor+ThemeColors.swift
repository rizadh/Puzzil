//
//  UIColor+ThemeColors.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import Foundation
import UIKit

private let pinkHue: CGFloat = 330 / 360
private let orangeHue: CGFloat = 30 / 360

private let backgroundSaturation: CGFloat = 0.2
private let foregroundSaturation: CGFloat = 0.8

private let backgroundBrightness: CGFloat = 1
private let foregroundBrightness: CGFloat = 1

extension UIColor {
    // Foreground colors
    static let themeForegroundPink = UIColor(
        hue: pinkHue,
        saturation: foregroundSaturation,
        brightness: foregroundBrightness,
        alpha: 1
    )
    static let themeForegroundOrange = UIColor(
        hue: orangeHue,
        saturation: foregroundSaturation,
        brightness: foregroundBrightness,
        alpha: 1
    )

    // Background colors
    static let themeBackgroundPink = UIColor(
        hue: pinkHue,
        saturation: backgroundSaturation,
        brightness: backgroundBrightness,
        alpha: 1
    )
    static let themeBackgroundOrange = UIColor(
        hue: orangeHue,
        saturation: backgroundSaturation,
        brightness: backgroundBrightness,
        alpha: 1
    )
}
