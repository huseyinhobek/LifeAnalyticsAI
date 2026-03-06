// MARK: - Tests.SeasonalityDetectionUseCase

import XCTest
@testable import LifeAnalyticsAI

final class SeasonalityDetectionUseCaseTests: XCTestCase {
    func testExecuteDetectsWeekendEffectAndMondaySyndrome() async {
        let useCase = SeasonalityDetectionUseCase()
        let points = makeMoodPoints(days: 28)

        let result = await useCase.execute(points: points)

        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result?.weekendEffect ?? 0, 0)
        XCTAssertGreaterThan(result?.mondaySyndromeStrength ?? 0, 0)
    }

    func testExecuteReturnsNilForInsufficientData() async {
        let useCase = SeasonalityDetectionUseCase()
        let points = makeMoodPoints(days: 10)

        let result = await useCase.execute(points: points)

        XCTAssertNil(result)
    }

    private func makeMoodPoints(days: Int) -> [TimeSeriesDataPoint] {
        let calendar = Calendar.current
        let start = Date().startOfDay.daysAgo(days)

        return (0..<days).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            let weekday = calendar.component(.weekday, from: date)

            let normalized: Double
            switch weekday {
            case 1, 7: // weekend
                normalized = 0.82
            case 2: // monday
                normalized = 0.42
            default:
                normalized = 0.62
            }

            return TimeSeriesDataPoint(
                id: UUID(),
                date: date,
                source: .mood,
                metric: .moodScore,
                rawValue: normalized * 5,
                normalizedValue: normalized
            )
        }
    }
}
