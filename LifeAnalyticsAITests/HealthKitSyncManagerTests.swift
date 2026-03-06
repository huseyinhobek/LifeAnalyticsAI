// MARK: - Tests.HealthKitSyncManager

import XCTest
@testable import LifeAnalyticsAI

final class HealthKitSyncManagerTests: XCTestCase {
    func testAuthorizationFlowSuccess() async throws {
        let mockService = MockHealthKitService()
        mockService.shouldAuthorize = true

        let result = try await mockService.requestAuthorization()

        XCTAssertTrue(result)
    }

    func testAuthorizationFlowDenied() async throws {
        let mockService = MockHealthKitService()
        mockService.shouldAuthorize = false

        let result = try await mockService.requestAuthorization()

        XCTAssertFalse(result)
    }

    func testSleepDataParsingReturnsRecords() async throws {
        let mockService = MockHealthKitService()
        mockService.sleepRecords = [sampleSleep(hours: 8), sampleSleep(hours: 7)]

        let records = try await mockService.fetchSleepData(from: Date().daysAgo(3), to: Date())

        XCTAssertEqual(records.count, 2)
        XCTAssertGreaterThan(records[0].totalMinutes, 0)
    }

    func testStepCountFetchReturnsValue() async throws {
        let mockService = MockHealthKitService()
        mockService.stepCount = 8342

        let steps = try await mockService.fetchStepCount(for: Date())

        XCTAssertEqual(steps, 8342)
    }

    func testSyncPersistsRecords() async throws {
        let mockService = MockHealthKitService()
        mockService.sleepRecords = [sampleSleep(hours: 8), sampleSleep(hours: 6)]
        let mockRepository = MockSleepRepository()
        let manager = HealthKitSyncManager(
            healthKitService: mockService,
            sleepRepository: mockRepository,
            defaults: UserDefaults(suiteName: #function)!,
            now: Date.init
        )

        let synced = try await manager.syncSleepData()
        let count = await mockRepository.count()

        XCTAssertEqual(synced, 2)
        XCTAssertEqual(count, 2)
    }

    func testSyncDuplicateHandlingUsesUpsert() async throws {
        let duplicateID = UUID()
        let first = sampleSleep(id: duplicateID, hours: 7)
        let updated = SleepRecord(
            id: duplicateID,
            date: first.date,
            bedtime: first.bedtime,
            wakeTime: first.wakeTime,
            totalMinutes: 510,
            deepSleepMinutes: first.deepSleepMinutes,
            remSleepMinutes: first.remSleepMinutes,
            lightSleepMinutes: first.lightSleepMinutes,
            efficiency: 0.92,
            source: .manual
        )

        let mockService = MockHealthKitService()
        mockService.sleepRecords = [first]
        let mockRepository = MockSleepRepository()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let manager = HealthKitSyncManager(
            healthKitService: mockService,
            sleepRepository: mockRepository,
            defaults: defaults,
            now: Date.init
        )

        _ = try await manager.syncSleepData()
        mockService.sleepRecords = [updated]
        _ = try await manager.syncSleepData()

        let count = await mockRepository.count()
        XCTAssertEqual(count, 1)
    }

    func testHeartRateFetchReturnsArray() async throws {
        let mockService = MockHealthKitService()
        mockService.heartRates = [62.0, 64.5, 61.2]

        let values = try await mockService.fetchHeartRate(from: Date().daysAgo(1), to: Date())

        XCTAssertEqual(values.count, 3)
    }

    func testBackgroundDeliverySetupFlag() async throws {
        let mockService = MockHealthKitService()

        try await mockService.setupBackgroundDelivery()

        XCTAssertTrue(mockService.setupBackgroundCalled)
    }

    private func sampleSleep(id: UUID = UUID(), hours: Int) -> SleepRecord {
        let wake = Date()
        let bed = wake.addingTimeInterval(TimeInterval(-hours * 3600))
        return SleepRecord(
            id: id,
            date: wake.startOfDay,
            bedtime: bed,
            wakeTime: wake,
            totalMinutes: hours * 60,
            deepSleepMinutes: 90,
            remSleepMinutes: 90,
            lightSleepMinutes: max(0, hours * 60 - 180),
            efficiency: 0.85,
            source: .manual
        )
    }
}
