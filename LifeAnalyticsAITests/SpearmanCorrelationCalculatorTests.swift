// MARK: - Tests.SpearmanCorrelationCalculator

import XCTest
@testable import LifeAnalyticsAI

final class SpearmanCorrelationCalculatorTests: XCTestCase {
    func testExecuteReturnsHighPositiveRankCorrelation() async {
        let calculator = SpearmanCorrelationCalculator()
        let lhs = makeSeries(values: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140], metric: .sleepHours, source: .sleep)
        let rhs = makeSeries(values: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], metric: .moodScore, source: .mood)

        let result = await calculator.execute(lhs: lhs, rhs: rhs, minimumPoints: 14)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.sampleSize, 14)
        XCTAssertEqual(result?.coefficient ?? 0, 1.0, accuracy: 0.0001)
    }

    func testExecuteCapturesNonLinearMonotonicRelation() async {
        let calculator = SpearmanCorrelationCalculator()
        let x = Array(1...16).map(Double.init)
        let y = x.map { $0 * $0 }

        let lhs = makeSeries(values: x, metric: .sleepHours, source: .sleep)
        let rhs = makeSeries(values: y, metric: .moodScore, source: .mood)

        let result = await calculator.execute(lhs: lhs, rhs: rhs, minimumPoints: 14)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.coefficient ?? 0, 1.0, accuracy: 0.0001)
    }

    func testExecuteReturnsNilWhenInsufficientData() async {
        let calculator = SpearmanCorrelationCalculator()
        let lhs = makeSeries(values: Array(1...10).map(Double.init), metric: .meetingCount, source: .calendar)
        let rhs = makeSeries(values: Array(1...10).map(Double.init), metric: .moodScore, source: .mood)

        let result = await calculator.execute(lhs: lhs, rhs: rhs, minimumPoints: 14)

        XCTAssertNil(result)
    }

    private func makeSeries(
        values: [Double],
        metric: TimeSeriesDataPoint.Metric,
        source: TimeSeriesDataPoint.Source
    ) -> [TimeSeriesDataPoint] {
        let today = Date().startOfDay
        return values.enumerated().map { index, value in
            let date = Calendar.current.date(byAdding: .day, value: index, to: today) ?? today
            return TimeSeriesDataPoint(
                id: UUID(),
                date: date,
                source: source,
                metric: metric,
                rawValue: value,
                normalizedValue: value / (values.max() ?? 1)
            )
        }
    }
}
