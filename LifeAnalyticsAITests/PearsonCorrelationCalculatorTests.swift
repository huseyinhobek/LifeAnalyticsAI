// MARK: - Tests.PearsonCorrelationCalculator

import XCTest
@testable import LifeAnalyticsAI

final class PearsonCorrelationCalculatorTests: XCTestCase {
    func testExecuteReturnsHighPositiveCorrelation() async {
        let calculator = PearsonCorrelationCalculator()
        let lhs = makeSeries(values: Array(1...20).map(Double.init), metric: .sleepHours, source: .sleep)
        let rhs = makeSeries(values: Array(1...20).map { Double($0) * 2 }, metric: .moodScore, source: .mood)

        let result = await calculator.execute(lhs: lhs, rhs: rhs, minimumPoints: 14)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.sampleSize, 20)
        XCTAssertEqual(result?.coefficient ?? 0, 1.0, accuracy: 0.0001)
    }

    func testExecuteReturnsNegativeCorrelation() async {
        let calculator = PearsonCorrelationCalculator()
        let lhs = makeSeries(values: Array(1...18).map(Double.init), metric: .meetingMinutes, source: .calendar)
        let rhs = makeSeries(values: Array(1...18).reversed().map(Double.init), metric: .moodScore, source: .mood)

        let result = await calculator.execute(lhs: lhs, rhs: rhs, minimumPoints: 14)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.sampleSize, 18)
        XCTAssertEqual(result?.coefficient ?? 0, -1.0, accuracy: 0.0001)
    }

    func testExecuteReturnsNilWhenInsufficientData() async {
        let calculator = PearsonCorrelationCalculator()
        let lhs = makeSeries(values: Array(1...10).map(Double.init), metric: .sleepHours, source: .sleep)
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
                normalizedValue: value / 20.0
            )
        }
    }
}
