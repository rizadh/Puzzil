//
//  UIColor+ThemeColors.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//


import UIKit

private let pinkHue: CGFloat = 345 / 360
private let themeForeground = UIColor(hue: pinkHue, saturation: 6 / 8, brightness: 1, alpha: 1)
private let themeBackground = UIColor(hue: pinkHue, saturation: 1 / 8, brightness: 1, alpha: 1)

extension UIColor {
    static let tile = themeForeground
    static let header = themeForeground
    static let board = themeBackground
    static let button = themeForeground
    static let pageControlActive = themeForeground
    static let pageControlInactive = themeBackground
}
