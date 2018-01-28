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

    private static let bestTimePathKey = "bestTimes"
    private static let bestTimesPath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(bestTimePathKey)

    var window: UIWindow?
    var bestTimes = [String: Double]() {
        didSet {
            try! saveBestTimes()
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        try? retrieveBestTimes()

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = BoardSelectorViewController()
        window!.makeKeyAndVisible()

        return true
    }

    func retrieveBestTimes() throws {
        bestTimes = try PropertyListDecoder().decode([String: Double].self, from: try Data(contentsOf: AppDelegate.bestTimesPath))
    }

    func saveBestTimes() throws -> Void {
        try PropertyListEncoder().encode(bestTimes).write(to: AppDelegate.bestTimesPath)
    }
}
