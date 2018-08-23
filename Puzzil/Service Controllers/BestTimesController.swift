//
//  BestTimesController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-02-12.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import os
import Foundation

class BestTimesController {
    enum UpdateResult {
        case created(time: Double)
        case replaced(oldTime: Double, newTime: Double)
        case preserved(oldTime: Double, newTime: Double)
    }

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
            using: didReceiveExternalChangeNotification
        )
        NSUbiquitousKeyValueStore.default.synchronize()
        mergeExternalKeys()
    }

    func boardWasSolved(boardStyle: BoardStyle, seconds newTime: Double) -> UpdateResult {
        let boardName = boardStyle.rawValue

        guard let existingTime = bestTimes[boardName] else {
            bestTimes[boardName] = newTime

            return .created(time: newTime)
        }

        if newTime < existingTime {
            bestTimes[boardName] = newTime

            return .replaced(oldTime: existingTime, newTime: newTime)
        } else {
            return .preserved(oldTime: existingTime, newTime: newTime)
        }
    }

    func getBestTime(for boardStyle: BoardStyle) -> Double? {
        return bestTimes[boardStyle.rawValue]
    }

    func resetBestTime(for boardStyle: BoardStyle) -> Double? {
        return bestTimes.removeValue(forKey: boardStyle.rawValue)
    }

    private func saveBestTimes() {
        UserDefaults.standard.set(bestTimes, forKey: BestTimesController.bestTimesKey)
        NSUbiquitousKeyValueStore.default.set(bestTimes.mapValues { NSNumber(value: $0) }, forKey: BestTimesController.bestTimesKey)
    }

    private func didReceiveExternalChangeNotification(_ notification: Notification) {
        mergeExternalKeys()
    }

    private func mergeExternalKeys() {
        if let remoteBestTimes =
            NSUbiquitousKeyValueStore.default.dictionary(forKey: BestTimesController.bestTimesKey) as? [String: NSNumber] {
            bestTimes.merge(remoteBestTimes.mapValues { Double(truncating: $0) }, uniquingKeysWith: min)
        }
    }
}
