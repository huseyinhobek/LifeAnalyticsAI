// MARK: - Tests.MoodDomainUseCases

import Foundation
import XCTest
@testable import LifeAnalyticsAI

final class MoodDomainUseCasesTests: XCTestCase {
    func testSaveMoodEntryUseCaseForwardsToRepository() async throws {
        let repository = TestMoodRepository()
        let useCase = SaveMoodEntryUseCase(repository: repository)
        let entry = makeMoodEntry(value: 4, dayOffset: -1)

        try await useCase.execute(entry)

        let saved = await repository.savedEntries
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.id, entry.id)
    }

    func testFetchMoodEntriesUseCaseForwardsDateRange() async throws {
        let repository = TestMoodRepository()
        let expected = [makeMoodEntry(value: 5, dayOffset: -2)]
        await repository.setFetchResult(expected)
        let useCase = FetchMoodEntriesUseCase(repository: repository)
        let from = Date().daysAgo(7)
        let to = Date()

        let result = try await useCase.execute(from: from, to: to)

        XCTAssertEqual(result, expected)
        let capturedRange = await repository.lastFetchRange
        XCTAssertEqual(capturedRange?.from.timeIntervalSince1970, from.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(capturedRange?.to.timeIntervalSince1970, to.timeIntervalSince1970, accuracy: 0.001)
    }

    func testMoodStatisticsAverageAndTrend() async throws {
        let repository = TestMoodRepository()
        let entries = [
            makeMoodEntry(value: 2, dayOffset: -12),
            makeMoodEntry(value: 2, dayOffset: -11),
            makeMoodEntry(value: 4, dayOffset: -2),
            makeMoodEntry(value: 5, dayOffset: -1)
        ]
        await repository.setFetchResult(entries)
        let calculator = MoodStatisticsCalculator(repository: repository)

        let average = try await calculator.averageMood(days: 14)
        let trend = try await calculator.moodTrend(weeks: 2)

        XCTAssertEqual(average, 3.25, accuracy: 0.0001)
        XCTAssertEqual(trend.direction, .up)
        XCTAssertGreaterThan(trend.weeklyChange, 0)
    }

    func testMoodStatisticsWeekdayWeekendDifferenceAndBestDayProfile() async throws {
        let repository = TestMoodRepository()
        let monday = date(year: 2026, month: 3, day: 2, hour: 10)
        let saturday = date(year: 2026, month: 3, day: 7, hour: 11)
        let entries = [
            MoodEntry(id: UUID(), date: monday.startOfDay, timestamp: monday, value: 4, note: nil, activities: [.work, .exercise]),
            MoodEntry(id: UUID(), date: monday.startOfDay, timestamp: monday.addingTimeInterval(60 * 60), value: 5, note: nil, activities: [.work]),
            MoodEntry(id: UUID(), date: saturday.startOfDay, timestamp: saturday, value: 2, note: nil, activities: [.social])
        ]
        await repository.setFetchResult(entries)
        let calculator = MoodStatisticsCalculator(repository: repository)

        let diff = try await calculator.weekdayWeekendDifference(days: 14)
        let profile = try await calculator.bestDayProfile(days: 14)

        XCTAssertEqual(diff.weekdayAverage, 4.5, accuracy: 0.0001)
        XCTAssertEqual(diff.weekendAverage, 2.0, accuracy: 0.0001)
        XCTAssertEqual(diff.difference, -2.5, accuracy: 0.0001)
        XCTAssertEqual(profile?.weekday, Calendar.current.component(.weekday, from: monday))
        XCTAssertEqual(profile?.topActivities.first, .work)
    }

    private func makeMoodEntry(value: Int, dayOffset: Int) -> MoodEntry {
        let ts = Date().daysAgo(abs(dayOffset))
        return MoodEntry(
            id: UUID(),
            date: ts.startOfDay,
            timestamp: dayOffset <= 0 ? ts : Date().addingTimeInterval(TimeInterval(dayOffset * 86_400)),
            value: value,
            note: nil,
            activities: [.work]
        )
    }

    private func date(year: Int, month: Int, day: Int, hour: Int) -> Date {
        let components = DateComponents(calendar: .current, year: year, month: month, day: day, hour: hour)
        return components.date ?? Date()
    }
}

private actor TestMoodRepository: MoodRepositoryProtocol {
    private(set) var savedEntries: [MoodEntry] = []
    private(set) var lastFetchRange: (from: Date, to: Date)?
    private var fetchResult: [MoodEntry] = []

    func setFetchResult(_ result: [MoodEntry]) {
        fetchResult = result
    }

    func saveMoodEntry(_ entry: MoodEntry) async throws {
        savedEntries.append(entry)
    }

    func fetchMoodEntries(from: Date, to: Date) async throws -> [MoodEntry] {
        lastFetchRange = (from, to)
        return fetchResult
    }

    func getAverageMood(days: Int) async throws -> Double {
        _ = days
        guard !fetchResult.isEmpty else { return 0 }
        let total = fetchResult.reduce(0) { $0 + Double($1.value) }
        return total / Double(fetchResult.count)
    }
}
