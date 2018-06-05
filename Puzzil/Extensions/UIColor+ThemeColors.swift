//
//  UIColor+ThemeColors.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

extension UIColor {
    private static let selectedColorTheme = ColorTheme.dark

    // MARK: - Theme Colors

    // MARK: - Background
    static let themeBackground = selectedColorTheme.background
    static let themePrimaryTextOnBackground = selectedColorTheme.primaryTextOnBackground
    static let themeSecondaryTextOnBackground = selectedColorTheme.secondaryTextOnBackground

    // MARK: - Primary
    static let themePrimary = selectedColorTheme.primary
    static let
    themePrimaryTextOnPrimary = selectedColorTheme.primaryTextOnPrimary

    // MARK: - Secondary
    static let themeSecondary = selectedColorTheme.secondary
    static let themePrimaryTextOnSecondary = selectedColorTheme.primaryTextOnSecondary
    static let themeSecondaryTextOnSecondary = selectedColorTheme.secondaryTextOnSecondary

    // MARK: - Properties

    var isLight: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)

        return white > 0.75
    }
}

private struct ColorTheme {
    let background: UIColor
    let primary: UIColor
    let secondary: UIColor
    let primaryTextOnBackground: UIColor
    let secondaryTextOnBackground: UIColor
    let primaryTextOnPrimary: UIColor
    let primaryTextOnSecondary: UIColor
    let secondaryTextOnSecondary: UIColor
}

extension ColorTheme {
    static let light = ColorTheme(
        background: UIColor(hue: 345 / 360, saturation: 0.05, brightness: 1, alpha: 1),
        primary: UIColor(hue: 345 / 360, saturation: 0.75, brightness: 1, alpha: 1),
        secondary: UIColor(hue: 345 / 360, saturation: 0.15, brightness: 1, alpha: 1),
        primaryTextOnBackground: .black,
        secondaryTextOnBackground: UIColor(white: 0.5, alpha: 1),
        primaryTextOnPrimary: .white,
        primaryTextOnSecondary: UIColor(hue: 345 / 360, saturation: 0.75, brightness: 0.9, alpha: 1),
        secondaryTextOnSecondary: UIColor(hue: 345 / 360, saturation: 0.5, brightness: 0.8, alpha: 1)
    )

    static let dark = ColorTheme(
        background: UIColor(hue: 345 / 360, saturation: 0.15, brightness: 0.2, alpha: 1),
        primary: UIColor(hue: 345 / 360, saturation:  0.75, brightness: 0.75, alpha: 1),
        secondary: UIColor(hue: 345 / 360, saturation: 0.15, brightness: 0.3, alpha: 1),
        primaryTextOnBackground: .white,
        secondaryTextOnBackground: UIColor(white: 0.5, alpha: 1),
        primaryTextOnPrimary: .white,
        primaryTextOnSecondary: .white,
        secondaryTextOnSecondary: UIColor(hue: 345 / 360, saturation: 0.15, brightness: 0.75, alpha: 1)
    )
}
