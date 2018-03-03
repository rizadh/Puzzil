//
//  UIColor+ThemeColors.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

extension UIColor {
    private static let selectedColorTheme = ColorTheme.original

    static let themeBackground = selectedColorTheme.background
    static let themeTile = selectedColorTheme.tile
    static let themeTileText = selectedColorTheme.tileText
    static let themeHeader = selectedColorTheme.header
    static let themeHeaderText = selectedColorTheme.headerText
    static let themeBoard = selectedColorTheme.board
    static let themeButton = selectedColorTheme.button
    static let themeButtonText = selectedColorTheme.buttonText
    static let themePageControlActive = selectedColorTheme.pageControlActive
    static let themePageControlInactive = selectedColorTheme.pageControlInactive
    static let themePrimaryText = selectedColorTheme.primaryText
    static let themeSecondaryText = selectedColorTheme.secondaryText

    var isLight: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)

        return white > 0.75
    }
}

private struct ColorTheme {
    let background: UIColor
    let tile: UIColor
    let tileText: UIColor
    let header: UIColor
    let headerText: UIColor
    let board: UIColor
    let button: UIColor
    let buttonText: UIColor
    let pageControlActive: UIColor
    let pageControlInactive: UIColor
    let primaryText: UIColor
    let secondaryText: UIColor
}

extension ColorTheme {
    static let original = ColorTheme(
        background: UIColor(white: 0.95, alpha: 1),
        tile: UIColor(hue: 345 / 360, saturation: 3 / 4, brightness: 1, alpha: 1),
        tileText: .white,
        header: UIColor(hue: 345 / 360, saturation: 3 / 4, brightness: 1, alpha: 1),
        headerText: .white,
        board: UIColor(hue: 345 / 360, saturation: 5 / 32, brightness: 1, alpha: 1),
        button: UIColor(hue: 345 / 360, saturation: 3 / 4, brightness: 1, alpha: 1),
        buttonText: .white,
        pageControlActive: UIColor(hue: 345 / 360, saturation: 3 / 4, brightness: 1, alpha: 1),
        pageControlInactive: UIColor(hue: 345 / 360, saturation: 5 / 32, brightness: 1, alpha: 1),
        primaryText: .black,
        secondaryText: UIColor(white: 0.5, alpha: 1)
    )

    static let darkPurple = ColorTheme(
        background: UIColor(red: 33 / 255, green: 33 / 255, blue: 33 / 255, alpha: 1),
        tile: UIColor(red: 88 / 255, green: 86 / 255, blue: 214 / 255, alpha: 1),
        tileText: .white,
        header: UIColor(red: 88 / 255, green: 86 / 255, blue: 214 / 255, alpha: 1),
        headerText: .white,
        board: UIColor(hue: 241 / 360, saturation: 0.12, brightness: 1, alpha: 1),
        button: UIColor(red: 88 / 255, green: 86 / 255, blue: 214 / 255, alpha: 1),
        buttonText: .white,
        pageControlActive: UIColor(red: 1, green: 204 / 255, blue: 0, alpha: 1),
        pageControlInactive: UIColor(hue: 241 / 360, saturation: 0.12, brightness: 1, alpha: 1),
        primaryText: .white,
        secondaryText: UIColor(white: 0.5, alpha: 1)
    )
}
