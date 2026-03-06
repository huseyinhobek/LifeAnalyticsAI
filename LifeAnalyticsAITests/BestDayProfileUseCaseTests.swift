// MARK: - Tests.BestDayProfileUseCase

import XCTest
@testable import LifeAnalyticsAI

final class BestDayProfileUseCaseTests: XCTestCase {
    func testExecuteReturnsBestWeekdayProfile() async {
        let useCase = BestDayProfileUseCase()
        let points = makePoints(days: 21)

        let result = await useCase.execute(points: points)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.dayOfWeek, 7)
        XCTAssertGreaterThan(result?.averageMood ?? 0, 4.2)
    }

    func testExecuteReturnsNilWhenNoMoodData() async {
        let useCase = BestDayProfileUseCase()
        let points = makePoints(days: 14).filter { $0.metric != .moodScore }

        let result = await useCase.execute(points: points)

        XCTAssertNil(result)
    }

    private func makePoints(days: Int) -> [TimeSeriesDataPoint] {
        let start = Date().startOfDay.daysAgo(days)
        var points: [TimeSeriesDataPoint] = []

        for day in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: day, to: start) ?? start
            let weekday = Calendar.current.component(.weekday, from: date)
            let mood = weekday == 7 ? 4.8 : 3.6
            let sleep = weekday == 7 ? 8.0 : 6.7
            let meetings = weekday == 7 ? 40.0 : 210.0

            points.append(TimeSeriesDataPoint(id: UUID(), date: date, source: .mood, metric: .moodScore, rawValue: mood, normalizedValue: mood / 5))
            points.append(TimeSeriesDataPoint(id: UUID(), date: date, source: .sleep, metric: .sleepHours, rawValue: sleep, normalizedValue: sleep / 12))
            points.append(TimeSeriesDataPoint(id: UUID(), date: date, source: .calendar, metric: .meetingMinutes, rawValue: meetings, normalizedValue: meetings / 720))
        }

        return points
    }
}
