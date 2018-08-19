//
//  ColorTheme.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-06-06.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

enum ColorTheme: Int {
    case light
    case dark

    static var selected: ColorTheme = .light

    static func fromUserDefaults() -> ColorTheme? {
        return ColorTheme(rawValue: UserDefaults().integer(forKey: "theme_preference"))
    }

    var background: UIColor {
        switch self {
        case .light:
            return UIColor(hue: 345 / 360, saturation: 0.05, brightness: 1, alpha: 1)
        case .dark:
            return UIColor(hue: 345 / 360, saturation: 0.15, brightness: 0.2, alpha: 1)
        }
    }

    var primary: UIColor {
        switch self {
        case .light:
            return UIColor(hue: 345 / 360, saturation: 0.75, brightness: 1, alpha: 1)
        case .dark:
            return UIColor(hue: 345 / 360, saturation: 0.75, brightness: 0.75, alpha: 1)
        }
    }

    var secondary: UIColor {
        switch self {
        case .light:
            return UIColor(hue: 345 / 360, saturation: 0.15, brightness: 1, alpha: 1)
        case .dark:
            return UIColor(hue: 345 / 360, saturation: 0.15, brightness: 0.3, alpha: 1)
        }
    }

    var primaryTextOnBackground: UIColor {
        switch self {
        case .light:
            return .black
        case .dark:
            return .white
        }
    }

    var secondaryTextOnBackground: UIColor {
        return UIColor(white: 0.5, alpha: 1)
    }

    var primaryTextOnPrimary: UIColor {
        return .white
    }

    var primaryTextOnSecondary: UIColor {
        switch self {
        case .light:
            return UIColor(hue: 345 / 360, saturation: 0.75, brightness: 0.9, alpha: 1)
        case .dark:
            return .white
        }
    }

    var secondaryTextOnSecondary: UIColor {
        switch self {
        case .light:
            return UIColor(hue: 345 / 360, saturation: 0.5, brightness: 0.8, alpha: 1)
        case .dark:
            return UIColor(hue: 345 / 360, saturation: 0.15, brightness: 0.75, alpha: 1)
        }
    }
}
