//
//  UIColor+ThemeColors.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//


import UIKit

private let themeHue: CGFloat = 345 / 360
private let themePrimary = UIColor(hue: themeHue, saturation: 6 / 8, brightness: 1, alpha: 1)
private let themeSecondary = UIColor(hue: themeHue, saturation: 1 / 8, brightness: 1, alpha: 1)

// TODO: Colors for new theme
//private let themePurplePrimary = UIColor(red: 88 / 255, green: 86 / 255, blue: 214 / 255, alpha: 1)
//private let themePurpleSecondary = UIColor(hue: 241 / 360, saturation: 0.12, brightness: 1, alpha: 1)

extension UIColor {
    static let themeBackground = UIColor.white
    static let themeTile = themePrimary
    static let themeTileText = UIColor.white
    static let themeHeader = themePrimary
    static let themeHeaderText = UIColor.white
    static let themeBoard = themeSecondary
    static let themeButton = themePrimary
    static let themeButtonText = UIColor.white
    static let themePageControlActive = themePrimary
    static let themePageControlInactive = themeSecondary
    static let themeText = UIColor.black

//    TODO: Potential colors for new theme
//    static let themeBackground = UIColor(red: 33 / 255, green: 33 / 255, blue: 33 / 255, alpha: 1)
//    static let themeTile = themePurplePrimary
//    static let themeTileText = UIColor.white
//    static let themeHeader = themePurplePrimary
//    static let themeHeaderText = UIColor.white
//    static let themeBoard = UIColor(hue: 241 / 360, saturation: 0.12, brightness: 1, alpha: 1)
//    static let themeButton = themePurplePrimary
//    static let themeButtonText = UIColor.white
//    static let themePageControlActive = UIColor(red: 1, green: 204 / 255, blue: 0, alpha: 1)
//    static let themePageControlInactive = themePurpleSecondary
//    static let themeText = UIColor.white
}
