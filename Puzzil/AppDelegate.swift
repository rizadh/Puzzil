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
    let boardConfigurations = [
        BoardConfiguration(name: "original", matrix: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, nil],
        ]),
        BoardConfiguration(name: "telephone", matrix: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
            [nil, 0, nil],
        ]),
//        BoardConfiguration(name: "puzzil", matrix: [
//            ["P", "U", "Z"],
//            ["Z", "I", "L"],
//            ["L", nil, nil],
//        ]),
    ]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = BoardSelectorViewController()
        window!.makeKeyAndVisible()

        return true
    }
}
