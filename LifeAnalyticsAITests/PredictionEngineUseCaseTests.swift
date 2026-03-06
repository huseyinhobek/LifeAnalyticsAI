// MARK: - Tests.PredictionEngineUseCase

import XCTest
@testable import LifeAnalyticsAI

final class PredictionEngineUseCaseTests: XCTestCase {
    func testExecutePredictsRisingMoodTrend() async {
        let useCase = PredictionEngineUseCase()
        let points = makeMoodPoints(values: Array(1...21).map { 2.0 + (Double($0) * 0.1) })

        let result = await useCase.execute(points: points)

        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result?.predictedMoodNextDay ?? 0, 3.5)
        XCTAssertEqual(result?.confidence, .medium)
    }

    func testExecuteReturnsHighConfidenceWithLongHistory() async {
        let useCase = PredictionEngineUseCase()
        let points = makeMoodPoints(values: Array(repeating: 4.0, count: 35))

        let result = await useCase.execute(points: points)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.confidence, .high)
        XCTAssertEqual(result?.predictedMoodNextWeekAverage ?? 0, 4.0, accuracy: 0.01)
    }

    func testExecuteReturnsNilForInsufficientData() async {
        let useCase = PredictionEngineUseCase()
        let points = makeMoodPoints(values: Array(repeating: 3.0, count: 10))

        let result = await useCase.execute(points: points)

        XCTAssertNil(result)
    }

    private func makeMoodPoints(values: [Double]) -> [TimeSeriesDataPoint] {
        let start = Date().startOfDay.daysAgo(values.count)

        return values.enumerated().map { index, mood in
            let date = Calendar.current.date(byAdding: .day, value: index, to: start) ?? start
            return TimeSeriesDataPoint(
                id: UUID(),
                date: date,
                source: .mood,
                metric: .moodScore,
                rawValue: mood,
                normalizedValue: mood / 5.0
            )
        }
    }
}
