// MARK: - Tests.AnomalyDetectionUseCase

import XCTest
@testable import LifeAnalyticsAI

final class AnomalyDetectionUseCaseTests: XCTestCase {
    func testExecuteDetectsHighAndLowAnomalies() async {
        let useCase = AnomalyDetectionUseCase()
        let points = makeSeries(values: [0.5, 0.52, 0.48, 0.51, 0.49, 0.95, 0.1])

        let anomalies = await useCase.execute(points: points, threshold: 1.5)

        XCTAssertEqual(anomalies.count, 2)
        XCTAssertTrue(anomalies.contains(where: { $0.direction == .high }))
        XCTAssertTrue(anomalies.contains(where: { $0.direction == .low }))
        XCTAssertTrue(anomalies.allSatisfy { abs($0.zScore) >= 1.5 })
    }

    func testExecuteReturnsEmptyWhenNoAnomaly() async {
        let useCase = AnomalyDetectionUseCase()
        let points = makeSeries(values: [0.45, 0.47, 0.46, 0.44, 0.48, 0.46, 0.47])

        let anomalies = await useCase.execute(points: points, threshold: 1.5)

        XCTAssertTrue(anomalies.isEmpty)
    }

    func testExecuteReturnsEmptyForSmallSeries() async {
        let useCase = AnomalyDetectionUseCase()
        let points = makeSeries(values: [0.2, 0.3, 0.8, 0.1])

        let anomalies = await useCase.execute(points: points, threshold: 1.5)

        XCTAssertTrue(anomalies.isEmpty)
    }

    private func makeSeries(values: [Double]) -> [TimeSeriesDataPoint] {
        let start = Date().startOfDay
        return values.enumerated().map { index, value in
            let date = Calendar.current.date(byAdding: .day, value: index, to: start) ?? start
            return TimeSeriesDataPoint(
                id: UUID(),
                date: date,
                source: .mood,
                metric: .moodScore,
                rawValue: value * 5,
                normalizedValue: value
            )
        }
    }
}
