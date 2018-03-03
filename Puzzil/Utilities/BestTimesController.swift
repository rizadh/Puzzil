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
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: nil, queue: .main,
                                               using: bestTimesDidChangeExternally)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func boardWasSolved(board: String, time: Double) -> (isBestTime: Bool, oldTime: Double?) {
        guard let oldTime = bestTimes[board] else {
            bestTimes[board] = time

            return (true, nil)
        }

        if time < oldTime {
            bestTimes[board] = time

            return (true, oldTime)
        } else {
            return (false, oldTime)
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
