// MARK: - Tests.ConfidenceScoringUseCase

import XCTest
@testable import LifeAnalyticsAI

final class ConfidenceScoringUseCaseTests: XCTestCase {
    func testExecuteAssignsHighConfidenceForStrongEffect() async {
        let useCase = ConfidenceScoringUseCase()
        let correlations = [
            CrossSourceCorrelation(
                id: UUID(),
                lhsMetric: .sleepHours,
                rhsMetric: .moodScore,
                pearson: 0.65,
                spearman: 0.62,
                sampleSize: 30
            )
        ]

        let results = await useCase.execute(correlations: correlations)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.confidence, .high)
        XCTAssertGreaterThan(results.first?.effectSize ?? 0, 0.6)
    }

    func testExecuteAssignsLowConfidenceBelowThreshold() async {
        let useCase = ConfidenceScoringUseCase()
        let correlations = [
            CrossSourceCorrelation(
                id: UUID(),
                lhsMetric: .meetingCount,
                rhsMetric: .moodScore,
                pearson: 0.1,
                spearman: 0.08,
                sampleSize: 28
            )
        ]

        let results = await useCase.execute(correlations: correlations)

        XCTAssertEqual(results.first?.confidence, .low)
    }

    func testExecuteAssignsLowConfidenceWhenSampleSizeInsufficient() async {
        let useCase = ConfidenceScoringUseCase()
        let correlations = [
            CrossSourceCorrelation(
                id: UUID(),
                lhsMetric: .meetingMinutes,
                rhsMetric: .sleepHours,
                pearson: 0.7,
                spearman: 0.68,
                sampleSize: 10
            )
        ]

        let results = await useCase.execute(correlations: correlations)

        XCTAssertEqual(results.first?.confidence, .low)
    }
}
