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
    var bestTimesController = BestTimesController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { _ in
            if let newTheme = ColorTheme.fromUserDefaults(),
                ColorTheme.selected != newTheme {
                self.themeWasChanged()
            }
        }

        loadMainViewController()

        return true
    }

    private func loadMainViewController() {
        BoardCell.flushCache()

        if let selectedColorTheme = ColorTheme.fromUserDefaults() {
            ColorTheme.selected = selectedColorTheme
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        let mainViewController = MainViewController()
        mainViewController.bestTimesController = bestTimesController
        window!.rootViewController = mainViewController
        window!.makeKeyAndVisible()
    }

    private func themeWasChanged() {
        // TODO: Display a global alert controller in a new window

        loadMainViewController()
    }
}
