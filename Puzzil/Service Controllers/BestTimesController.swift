//
//  BestTimesController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-02-12.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import CloudKit
import Foundation
import os

class BestTimesController {
    private typealias BestTimes = [BoardStyle: BestTimeEntry]

    static let shared = BestTimesController()

    private let database = CKContainer.default().privateCloudDatabase
    private var subscriptionHandlers = [() -> Void]()
    private var bestTimes = BestTimes() {
        didSet {
            do {
                try saveBestTimesToDisk()
                saveBestTimesToCloud()
                notifyAllSubscribers()
                os_log("Saved best times to disk.")
            } catch {
                os_log("Could not save best times to disk.", type: .error)
            }
        }
    }

    // MARK: - Initializers

    private init() {
        guard let bestTimesFromDisk = try? readBestTimesFromDisk() else {
            os_log("Could not read best times from disk.", type: .error)
            return
        }

        os_log("Read best times from disk.")

        bestTimes = bestTimesFromDisk

        readBestTimesFromCloud { bestTimesFromCloud in
            self.bestTimes.merge(bestTimesFromCloud) { localEntry, remoteEntry in
                let localDate: Date
                let remoteDate: Date

                switch localEntry {
                case let .created(solveDate, _, _):
                    localDate = solveDate
                case let .deleted(deletionDate, _):
                    localDate = deletionDate
                }

                switch remoteEntry {
                case let .created(solveDate, _, _):
                    remoteDate = solveDate
                case let .deleted(deletionDate, _):
                    remoteDate = deletionDate
                }

                return localDate < remoteDate ? remoteEntry : localEntry
            }

            self.saveBestTimesToCloud()
        }
    }

    // MARK: - Subscription Handling

    func subscribeToChanges(_ handler: @escaping () -> Void) {
        subscriptionHandlers.append(handler)
    }

    private func notifyAllSubscribers() {
        subscriptionHandlers.forEach { $0() }
    }

    // MARK: - Best Time Accessors

    func getBestTime(for boardStyle: BoardStyle) -> Double? {
        guard let bestTimeEntry = bestTimes[boardStyle],
            case let .created(_, _, solveTime) = bestTimeEntry
        else { return nil }

        return solveTime
    }

    func saveBestTime(_ time: Double, for boardStyle: BoardStyle) -> UpdateResult {
        guard let bestTimeEntry = bestTimes[boardStyle],
            case let .created(_, _, solveTime) = bestTimeEntry
        else {
            bestTimes[boardStyle] = .created(solveDate: Date(), synced: false, solveTime: time)

            return .created(time: time)
        }

        if time < solveTime {
            bestTimes[boardStyle] = .created(solveDate: Date(), synced: false, solveTime: time)
            return .replaced(oldTime: solveTime, newTime: time)
        } else {
            return .preserved(oldTime: solveTime, newTime: time)
        }
    }

    func removeBestTime(for boardStyle: BoardStyle) {
        bestTimes[boardStyle] = .deleted(deletionDate: Date(), synced: false)
    }

    // MARK: - Disk Syncing

    private func saveBestTimesToDisk() throws {
        let data = try JSONEncoder().encode(bestTimes)
        UserDefaults.standard.set(data, forKey: .customKey(.bestTimes))
    }

    private func readBestTimesFromDisk() throws -> BestTimes {
        guard let data = UserDefaults.standard.data(forKey: .customKey(.bestTimes))
        else { return [:] }

        return try JSONDecoder().decode(BestTimes.self, from: data)
    }

    // MARK: - iCloud Syncing

    private func saveBestTimesToCloud() {
        for (boardStyle, bestTimeEntry) in bestTimes {
            switch bestTimeEntry {
            case let .created(solveDate, false, solveTime):
                createBestTimeInCloud(solveTime, for: boardStyle, createdAt: solveDate)
            case let .deleted(deletionDate, false):
                deleteBestTimeInCloud(for: boardStyle, deletedAt: deletionDate)
                bestTimes[boardStyle] = .deleted(deletionDate: deletionDate, synced: true)
            default:
                break
            }
        }
    }

    private func createBestTimeInCloud(_ solveTime: Double, for boardStyle: BoardStyle, createdAt solveDate: Date) {
        fetchSavableRecord(for: boardStyle) { record in
            record[.recordKey(.boardStyle)] = boardStyle.rawValue
            record[.recordKey(.solveTime)] = solveTime
            record[.recordKey(.solveDate)] = solveDate
            record[.recordKey(.isDeleted)] = false
            self.database.save(record) { _, error in
                guard error == nil else {
                    os_log("Could not save best time to iCloud.", type: .error)
                    return
                }

                os_log("Saved created best time to iCloud.")
                self.bestTimes[boardStyle] = .created(solveDate: solveDate, synced: true, solveTime: solveTime)
            }
        }
    }

    private func deleteBestTimeInCloud(for boardStyle: BoardStyle, deletedAt deletionDate: Date) {
        fetchSavableRecord(for: boardStyle) { record in
            record[.recordKey(.isDeleted)] = true
            record[.recordKey(.deletionDate)] = deletionDate
            self.database.save(record, completionHandler: { _, error in
                guard error == nil else {
                    os_log("Could not save deleted best time to iCloud.", type: .error)
                    return
                }

                os_log("Saved deleted best time to iCloud.")
                self.bestTimes[boardStyle] = .deleted(deletionDate: deletionDate, synced: true)
            })
        }
    }

    private func fetchSavableRecord(for boardStyle: BoardStyle, completionHandler: @escaping (CKRecord) -> Void) {
        database.fetch(withRecordID: .init(for: boardStyle)) { record, _ in
            completionHandler(record ?? CKRecord(recordType: .bestTimes, recordID: .init(for: boardStyle)))
        }
    }

    private func readBestTimesFromCloud(completionHandler: @escaping (BestTimes) -> Void) {
        let query = CKQuery(recordType: .bestTimes, predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { records, error in
            guard let records = records, error == nil else {
                os_log("Could not fetch best times from iCloud.", type: .error)
                return
            }

            var fetchedBestTimes = BestTimes()

            records.forEach { record in
                guard let boardStyleRawValue = record[.recordKey(.boardStyle)] as? String,
                    let boardStyle = BoardStyle(rawValue: boardStyleRawValue),
                    let isDeleted = record[.recordKey(.isDeleted)] as? Bool else {
                    os_log("Could not parse best time record from iCloud.", type: .error)
                    return
                }

                if isDeleted {
                    guard let deletionDate = record[.recordKey(.deletionDate)] as? Date else {
                        os_log("Could not parse deleted best time record from iCloud.", type: .error)
                        return
                    }

                    os_log("Parsed deleted best time record from iCloud.")
                    fetchedBestTimes[boardStyle] = .deleted(deletionDate: deletionDate, synced: true)
                } else {
                    guard let solveDate = record[.recordKey(.solveDate)] as? Date,
                        let solveTime = record[.recordKey(.solveTime)] as? Double else {
                        os_log("Could not parse created best time record from iCloud.", type: .error)
                        return
                    }

                    os_log("Parsed created best time record from iCloud.")
                    fetchedBestTimes[boardStyle] = .created(solveDate: solveDate, synced: true, solveTime: solveTime)
                }
            }

            completionHandler(fetchedBestTimes)
        }
    }
}

// MARK: - Custom CKRecord Keys

private extension String {
    enum RecordKey: String {
        case boardStyle
        case isDeleted
        case solveDate
        case solveTime
        case deletionDate
    }

    static func recordKey(_ key: RecordKey) -> String {
        return key.rawValue
    }
}

// MARK: - Custom CKRecord.RecordType

private extension CKRecord.RecordType {
    static let bestTimes = "BestTimes"
}

// MARK: - Custom CKRecord.ID

private extension CKRecord.ID {
    convenience init(for boardStyle: BoardStyle) {
        self.init(recordName: boardStyle.rawValue)
    }
}

// MARK: - BestTimesController.UpdateResult

extension BestTimesController {
    enum UpdateResult {
        case created(time: Double)
        case replaced(oldTime: Double, newTime: Double)
        case preserved(oldTime: Double, newTime: Double)
    }
}

// MARK: - BestTimesController.BestTimeEntry

private extension BestTimesController {
    enum BestTimeEntry: Codable {
        case created(solveDate: Date, synced: Bool, solveTime: Double)
        case deleted(deletionDate: Date, synced: Bool)

        private enum CodingKeys: CodingKey {
            case date
            case synced
            case solveTime
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let date = try container.decode(Date.self, forKey: .date)
            let synced = try container.decode(Bool.self, forKey: .synced)
            do {
                let solveTime = try container.decode(Double.self, forKey: .solveTime)
                self = .created(solveDate: date, synced: synced, solveTime: solveTime)
            } catch {
                self = .deleted(deletionDate: date, synced: synced)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .created(solveDate, synced, solveTime):
                try container.encode(solveDate, forKey: .date)
                try container.encode(synced, forKey: .synced)
                try container.encode(solveTime, forKey: .solveTime)
            case let .deleted(deletionDate, synced):
                try container.encode(deletionDate, forKey: .date)
                try container.encode(synced, forKey: .synced)
            }
        }
    }
}
