// MARK: - Data.DataSources.HealthKit

import Foundation

final class HealthKitSyncManager {
    private let healthKitService: HealthKitServiceProtocol
    private let sleepRepository: SleepRepositoryProtocol
    private let defaults: UserDefaults
    private let now: () -> Date

    private enum Keys {
        static let lastSleepSyncDate = "healthkit.lastSleepSyncDate"
    }

    init(
        healthKitService: HealthKitServiceProtocol,
        sleepRepository: SleepRepositoryProtocol,
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.healthKitService = healthKitService
        self.sleepRepository = sleepRepository
        self.defaults = defaults
        self.now = now
    }

    @discardableResult
    func syncSleepData() async throws -> Int {
        let endDate = now()
        let startDate = lastSleepSyncDate ?? Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

        let records = try await healthKitService.fetchSleepData(from: startDate, to: endDate)

        guard !records.isEmpty else {
            defaults.set(endDate, forKey: Keys.lastSleepSyncDate)
            AppLogger.health.info("HealthKit sleep sync finished: no new records")
            return 0
        }

        var syncedCount = 0
        for record in records {
            try await sleepRepository.saveSleepRecord(record)
            syncedCount += 1
        }

        defaults.set(endDate, forKey: Keys.lastSleepSyncDate)
        AppLogger.health.info("HealthKit sleep sync finished: \(syncedCount) records")
        return syncedCount
    }

    var lastSleepSyncDate: Date? {
        defaults.object(forKey: Keys.lastSleepSyncDate) as? Date
    }
}
