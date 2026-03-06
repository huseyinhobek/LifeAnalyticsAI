// MARK: - Tests.CrossSourceAnalysisUseCase

import XCTest
@testable import LifeAnalyticsAI

final class CrossSourceAnalysisUseCaseTests: XCTestCase {
    func testExecuteReturnsCorrelationsForConfiguredPairs() async {
        let useCase = CrossSourceAnalysisUseCase()
        let points = makePoints(days: 30)

        let results = await useCase.execute(points: points)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.sampleSize >= 14 })
    }

    func testExecuteReturnsEmptyForInsufficientData() async {
        let useCase = CrossSourceAnalysisUseCase()
        let points = makePoints(days: 10)

        let results = await useCase.execute(points: points)

        XCTAssertTrue(results.isEmpty)
    }

    private func makePoints(days: Int) -> [TimeSeriesDataPoint] {
        let start = Date().startOfDay.daysAgo(days)
        var points: [TimeSeriesDataPoint] = []

        for day in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: day, to: start) ?? start
            let sleep = 0.3 + Double(day) / Double(max(1, days)) * 0.5
            let mood = 0.25 + Double(day) / Double(max(1, days)) * 0.55
            let meetings = 0.8 - Double(day) / Double(max(1, days)) * 0.6
            let meetingCount = 0.75 - Double(day) / Double(max(1, days)) * 0.45

            points.append(makePoint(date: date, source: .sleep, metric: .sleepHours, normalizedValue: sleep, rawValue: sleep * 10))
            points.append(makePoint(date: date, source: .mood, metric: .moodScore, normalizedValue: mood, rawValue: mood * 5))
            points.append(makePoint(date: date, source: .calendar, metric: .meetingMinutes, normalizedValue: meetings, rawValue: meetings * 600))
            points.append(makePoint(date: date, source: .calendar, metric: .meetingCount, normalizedValue: meetingCount, rawValue: meetingCount * 10))
        }

        return points
    }

    private func makePoint(
        date: Date,
        source: TimeSeriesDataPoint.Source,
        metric: TimeSeriesDataPoint.Metric,
        normalizedValue: Double,
        rawValue: Double
    ) -> TimeSeriesDataPoint {
        TimeSeriesDataPoint(
            id: UUID(),
            date: date,
            source: source,
            metric: metric,
            rawValue: rawValue,
            normalizedValue: normalizedValue
        )
    }
}
