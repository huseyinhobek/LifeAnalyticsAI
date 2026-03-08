// MARK: - Tests.SleepDomainUseCases

import Foundation
import XCTest
@testable import LifeAnalyticsAI

final class SleepDomainUseCasesTests: XCTestCase {
    func testFetchSleepDataUseCaseReturnsRepositoryData() async throws {
        let repository = TestSleepRepository()
        let expected = [makeRecord(totalMinutes: 420, dayOffset: -1)]
        await repository.setFetchResult(expected)
        let useCase = FetchSleepDataUseCase(repository: repository)

        let result = try await useCase.execute(days: 7)

        XCTAssertEqual(result, expected)
        let range = await repository.lastFetchRange
        XCTAssertNotNil(range)
    }

    func testSleepStatisticsAverageTrendAndBestWorst() async throws {
        let repository = TestSleepRepository()
        let records = [
            makeRecord(totalMinutes: 360, dayOffset: -13, efficiency: 0.70),
            makeRecord(totalMinutes: 390, dayOffset: -10, efficiency: 0.74),
            makeRecord(totalMinutes: 450, dayOffset: -2, efficiency: 0.90),
            makeRecord(totalMinutes: 480, dayOffset: -1, efficiency: 0.93)
        ]
        await repository.setFetchResult(records)
        let calculator = SleepStatisticsCalculator(repository: repository)

        let average = try await calculator.averageDuration(days: 14)
        let trend = try await calculator.sleepTrend(weeks: 2)
        let best = try await calculator.bestNight(days: 14)
        let worst = try await calculator.worstNight(days: 14)
        let efficiency = try await calculator.averageEfficiency(days: 14)

        XCTAssertEqual(average, 7.0, accuracy: 0.0001)
        XCTAssertEqual(trend.direction, .up)
        XCTAssertGreaterThan(trend.weeklyChangeHours, 0)
        XCTAssertEqual(best?.totalMinutes, 480)
        XCTAssertEqual(worst?.totalMinutes, 360)
        XCTAssertEqual(efficiency, 0.8175, accuracy: 0.0001)
    }

    func testSleepStatisticsBedtimeConsistency() async throws {
        let repository = TestSleepRepository()
        let base = date(year: 2026, month: 3, day: 1, hour: 22, minute: 0)
        let records = [
            makeRecord(totalMinutes: 420, bedtime: base, wakeOffsetHours: 7),
            makeRecord(totalMinutes: 420, bedtime: base.addingTimeInterval(60 * 30), wakeOffsetHours: 7),
            makeRecord(totalMinutes: 420, bedtime: base.addingTimeInterval(60 * 60), wakeOffsetHours: 7)
        ]
        await repository.setFetchResult(records)
        let calculator = SleepStatisticsCalculator(repository: repository)

        let deviation = try await calculator.bedtimeConsistency(days: 30)

        XCTAssertGreaterThan(deviation, 0)
    }

    private func makeRecord(totalMinutes: Int, dayOffset: Int, efficiency: Double = 0.8) -> SleepRecord {
        let date = Date().daysAgo(abs(dayOffset)).startOfDay
        return makeRecord(totalMinutes: totalMinutes, bedtime: date.addingTimeInterval(60 * 60 * 22), wakeOffsetHours: 7, efficiency: efficiency)
    }

    private func makeRecord(totalMinutes: Int, bedtime: Date, wakeOffsetHours: Int, efficiency: Double = 0.8) -> SleepRecord {
        SleepRecord(
            id: UUID(),
            date: bedtime.startOfDay,
            bedtime: bedtime,
            wakeTime: bedtime.addingTimeInterval(TimeInterval(wakeOffsetHours * 60 * 60)),
            totalMinutes: totalMinutes,
            deepSleepMinutes: totalMinutes / 5,
            remSleepMinutes: totalMinutes / 5,
            lightSleepMinutes: totalMinutes - (2 * (totalMinutes / 5)),
            efficiency: efficiency,
            source: .healthKit,
            isAboveAverage: nil
        )
    }

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        let components = DateComponents(calendar: .current, year: year, month: month, day: day, hour: hour, minute: minute)
        return components.date ?? Date()
    }
}

private actor TestSleepRepository: SleepRepositoryProtocol {
    private var records: [SleepRecord] = []
    private(set) var lastFetchRange: (from: Date, to: Date)?

    func setFetchResult(_ value: [SleepRecord]) {
        records = value
    }

    func fetchSleepRecords(from: Date, to: Date) async throws -> [SleepRecord] {
        lastFetchRange = (from, to)
        return records
    }

    func saveSleepRecord(_ record: SleepRecord) async throws {
        _ = record
    }

    func getAverageSleep(days: Int) async throws -> Double {
        _ = days
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.totalHours }
        return total / Double(records.count)
    }
}
