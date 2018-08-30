//
//  AppDelegate.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { _ in
            if let newTheme = ColorTheme.fromUserDefaults(),
                ColorTheme.selected != newTheme {
                self.themeWasChanged()
            }
        }

        loadMainViewController()

        UserDefaults().register(defaults: [
            .customKey(.tapToMove): true,
            .customKey(.themePreference): ColorTheme.light.rawValue,
        ])

        return true
    }

    private func loadMainViewController() {
        if let selectedColorTheme = ColorTheme.fromUserDefaults() {
            ColorTheme.selected = selectedColorTheme
        }

        BoardCell.flushCache()
        BoardCell.generateSnapshots()

        window = UIWindow(frame: UIScreen.main.bounds)
        let mainViewController = MainViewController()
        window!.rootViewController = mainViewController
        window!.makeKeyAndVisible()
    }

    private func themeWasChanged() {
        // TODO: Display a global alert controller in a new window

        loadMainViewController()
    }
}

enum CustomUserDefaultsKey: String {
    case tapToMove
    case themePreference
    case bestTimes
}

extension String {
    static func customKey(_ key: CustomUserDefaultsKey) -> String {
        return key.rawValue
    }
}
