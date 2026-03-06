// MARK: - Tests.MockHealthKit

import Foundation
@testable import LifeAnalyticsAI

final class MockHealthKitService: HealthKitServiceProtocol {
    var shouldAuthorize = true
    var isAuthorizedValue = true
    var sleepRecords: [SleepRecord] = []
    var stepCount = 0
    var heartRates: [Double] = []
    var setupBackgroundCalled = false

    func requestAuthorization() async throws -> Bool {
        shouldAuthorize
    }

    func isAuthorized() -> Bool {
        isAuthorizedValue
    }

    func fetchSleepData(from: Date, to: Date) async throws -> [SleepRecord] {
        sleepRecords.filter { $0.date >= from.startOfDay && $0.date <= to.endOfDay }
    }

    func fetchStepCount(for date: Date) async throws -> Int {
        stepCount
    }

    func fetchHeartRate(from: Date, to: Date) async throws -> [Double] {
        heartRates
    }

    func setupBackgroundDelivery() async throws {
        setupBackgroundCalled = true
    }
}

actor MockSleepRepository: SleepRepositoryProtocol {
    private(set) var records: [SleepRecord] = []

    func fetchSleepRecords(from: Date, to: Date) async throws -> [SleepRecord] {
        records.filter { $0.date >= from.startOfDay && $0.date <= to.endOfDay }
    }

    func saveSleepRecord(_ record: SleepRecord) async throws {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
    }

    func getAverageSleep(days: Int) async throws -> Double {
        let selected = records.filter { $0.date >= Date().daysAgo(days) }
        guard !selected.isEmpty else { return 0 }
        return selected.map(\.totalHours).reduce(0, +) / Double(selected.count)
    }

    func count() async -> Int { records.count }
}
