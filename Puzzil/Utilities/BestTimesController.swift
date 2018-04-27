//
//  BestTimesController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-02-12.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

class BestTimesController {
    private static var bestTimesKey = "bestTimes"

    private var bestTimes =
        UserDefaults.standard.dictionary(forKey: BestTimesController.bestTimesKey) as? [String: Double]
        ?? [String: Double]()
    { didSet { saveBestTimes() } }

    init() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            queue: .main,
            using: bestTimesDidChangeExternally
        )
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func boardWasSolved(board: String, seconds newTime: Double) -> BestTimeUpdateResult {
        guard let existingTime = bestTimes[board] else {
            bestTimes[board] = newTime

            return .created
        }

        if newTime < existingTime {
            bestTimes[board] = newTime

            return .replaced(oldTime: existingTime)
        } else {
            return .preserved(bestTime: existingTime)
        }
    }

    func getBestTime(for board: String) -> Double? {
        return bestTimes[board]
    }

    func resetBestTime(for board: String) -> Double? {
        return bestTimes.removeValue(forKey: board)
    }

    private func saveBestTimes() {
        UserDefaults.standard.set(bestTimes, forKey: BestTimesController.bestTimesKey)
        NSUbiquitousKeyValueStore.default.set(bestTimes, forKey: BestTimesController.bestTimesKey)
    }

    private func bestTimesDidChangeExternally(notification: Notification) {
        if let remoteBestTimes =
            NSUbiquitousKeyValueStore.default.dictionary(forKey: BestTimesController.bestTimesKey) as? [String: Double] {
            bestTimes.merge(remoteBestTimes, uniquingKeysWith: min)
        }
    }
}

enum BestTimeUpdateResult {
    case created
    case replaced(oldTime: Double)
    case preserved(bestTime: Double)
}
