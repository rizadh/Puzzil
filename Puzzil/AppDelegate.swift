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
    var boardScrambler = BoardScrambler()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.backgroundColor = .themeBackground
        window!.rootViewController = BoardSelectorViewController()
        window!.makeKeyAndVisible()

        return true
    }
}
