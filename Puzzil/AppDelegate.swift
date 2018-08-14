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
            if ColorTheme.loadFromUserDefaults() {
                self.loadMainViewController()
            }
        }

        _ = ColorTheme.loadFromUserDefaults()
        loadMainViewController()

        return true
    }

    private func loadMainViewController() {
        window = UIWindow(frame: UIScreen.main.bounds)
        let mainViewController = MainViewController()
        mainViewController.bestTimesController = bestTimesController
        window!.rootViewController = mainViewController
        window!.makeKeyAndVisible()
    }
}
