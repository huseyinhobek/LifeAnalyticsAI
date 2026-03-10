// MARK: - Tests.InsightPrioritizationUseCase

import XCTest
@testable import LifeAnalyticsAI

final class InsightPrioritizationUseCaseTests: XCTestCase {
    func testExecuteRanksHigherConfidenceAndCriticalTypesFirst() async {
        let useCase = InsightPrioritizationUseCase()
        let insights = [
            makeInsight(type: .trend, confidence: .low, daysAgo: 0),
            makeInsight(type: .anomaly, confidence: .high, daysAgo: 1),
            makeInsight(type: .prediction, confidence: .medium, daysAgo: 0)
        ]

        let result = await useCase.execute(insights: insights, top: 3)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first?.insight.type, .anomaly)
        XCTAssertTrue((result.first?.priorityScore ?? 0) >= (result.last?.priorityScore ?? 0))
    }

    func testExecuteRespectsTopLimit() async {
        let useCase = InsightPrioritizationUseCase()
        let insights = [
            makeInsight(type: .correlation, confidence: .high, daysAgo: 0),
            makeInsight(type: .prediction, confidence: .high, daysAgo: 0),
            makeInsight(type: .trend, confidence: .medium, daysAgo: 0)
        ]

        let result = await useCase.execute(insights: insights, top: 2)

        XCTAssertEqual(result.count, 2)
    }

    private func makeInsight(
        type: Insight.InsightType,
        confidence: Insight.ConfidenceLevel,
        daysAgo: Int
    ) -> Insight {
        Insight(
            id: UUID(),
            date: Date().daysAgo(daysAgo),
            type: type,
            title: "Test",
            body: "Test",
            confidenceLevel: confidence,
            relatedMetrics: [],
            userFeedback: nil
        )
    }
}
