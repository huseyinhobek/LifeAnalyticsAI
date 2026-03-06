// MARK: - Tests.NormalizeTimeSeriesDataUseCase

import XCTest
@testable import LifeAnalyticsAI

final class NormalizeTimeSeriesDataUseCaseTests: XCTestCase {
    func testExecuteProducesSortedCommonSeries() async {
        let useCase = NormalizeTimeSeriesDataUseCase()
        let sleep = MockDataGenerator.generateSleepRecords(days: 30)
        let mood = MockDataGenerator.generateMoodEntries(days: 30)
        let events = MockDataGenerator.generateCalendarEvents(days: 30)

        let points = await useCase.execute(sleepRecords: sleep, moodEntries: mood, calendarEvents: events)

        XCTAssertFalse(points.isEmpty)
        var isSorted = true
        for index in 1..<points.count {
            if points[index - 1].date > points[index].date {
                isSorted = false
                break
            }
        }
        XCTAssertTrue(isSorted)
    }

    func testNormalizeMoodEntriesKeepsRangeInBounds() async {
        let useCase = NormalizeTimeSeriesDataUseCase()
        let mood = MockDataGenerator.generateMoodEntries(days: 30)

        let points = await useCase.normalizeMoodEntries(mood)

        XCTAssertEqual(points.count, mood.count)
        XCTAssertTrue(points.allSatisfy { (0...1).contains($0.normalizedValue) })
        XCTAssertTrue(points.allSatisfy { $0.metric == .moodScore && $0.source == .mood })
    }

    func testNormalizeCalendarEventsGeneratesDailyCountAndMinutesPoints() async {
        let useCase = NormalizeTimeSeriesDataUseCase()
        let events = MockDataGenerator.generateCalendarEvents(days: 30)

        let points = await useCase.normalizeCalendarEvents(events)

        XCTAssertFalse(points.isEmpty)
        let grouped = Dictionary(grouping: points, by: { $0.date.startOfDay })
        XCTAssertTrue(grouped.values.allSatisfy { dayPoints in
            let metrics = Set(dayPoints.map(\.metric))
            return metrics.contains(.meetingCount) && metrics.contains(.meetingMinutes)
        })
    }
}
