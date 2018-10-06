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
    static let colorThemeDidChangeNotification =
        NSNotification.Name(rawValue: "com.rizadh.Puzzil.themeChangedNotification")

    var window: UIWindow?
    var lastBoardStyle: BoardStyle? {
        didSet { setShortcutItems() }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification,
                                               object: nil,
                                               queue: nil) { _ in
            if let newTheme = ColorTheme.fromUserDefaults(),
                ColorTheme.selected != newTheme {
                ColorTheme.selected = newTheme
                NotificationCenter.default.post(name: AppDelegate.colorThemeDidChangeNotification, object: self)
            }
        }

        if let selectedColorTheme = ColorTheme.fromUserDefaults() {
            ColorTheme.selected = selectedColorTheme
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        let mainViewController = MainViewController()
        window!.rootViewController = mainViewController
        window!.makeKeyAndVisible()

        UserDefaults().register(defaults: [
            .customKey(.tapToMove): true,
            .customKey(.themePreference): ColorTheme.light.rawValue,
        ])

        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            handleShortcutItem(shortcutItem)
            return false
        }

        return true
    }

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        handleShortcutItem(shortcutItem)
        completionHandler(true)
    }

    private func setShortcutItems() {
        if let shortcutItem = shortcutItemForLastBoard() {
            UIApplication.shared.shortcutItems = [shortcutItem]
        }
    }

    private func shortcutItemForLastBoard() -> UIApplicationShortcutItem? {
        return lastBoardStyle.map {
            UIApplicationShortcutItem(
                type: "startGame",
                localizedTitle: "Play Last Board",
                localizedSubtitle: $0.rawValue.capitalized,
                icon: UIApplicationShortcutIcon(type: .play),
                userInfo: [
                    "boardStyle": $0.rawValue as NSSecureCoding,
                ]
            )
        }
    }

    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        precondition(shortcutItem.type == "startGame")

        let mainViewController = window?.rootViewController as! MainViewController
        let rawBoardStyle = shortcutItem.userInfo?["boardStyle"] as! String
        let boardStyle = BoardStyle(rawValue: rawBoardStyle)!
        mainViewController.automaticallyStartGame(for: boardStyle)
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
