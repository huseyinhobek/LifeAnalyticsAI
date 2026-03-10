// MARK: - Tests.UpdateInsightFeedbackUseCase

import XCTest
@testable import LifeAnalyticsAI

final class UpdateInsightFeedbackUseCaseTests: XCTestCase {
    func testExecuteUpdatesRepositoryAndPromptOptimizer() async throws {
        let repository = StubInsightRepositoryForFeedback()
        let optimizer = StubPromptFeedbackOptimizer()
        let useCase = UpdateInsightFeedbackUseCase(
            repository: repository,
            promptFeedbackOptimizer: optimizer
        )
        let insight = makeInsight()

        try await useCase.execute(insight: insight, feedback: .helpful)

        let repositoryCalls = await repository.updateCalls
        let optimizerCalls = optimizer.recordCalls
        XCTAssertEqual(repositoryCalls.count, 1)
        XCTAssertEqual(optimizerCalls.count, 1)
        XCTAssertEqual(repositoryCalls.first?.insightId, insight.id)
        XCTAssertEqual(optimizerCalls.first?.feedback, .helpful)
    }

    private func makeInsight() -> Insight {
        Insight(
            id: UUID(),
            date: Date(),
            type: .trend,
            title: "Trend",
            body: "Body",
            confidenceLevel: .medium,
            relatedMetrics: [],
            userFeedback: nil
        )
    }
}

private actor StubInsightRepositoryForFeedback: InsightRepositoryProtocol {
    private(set) var updateCalls: [(insightId: UUID, feedback: Insight.UserFeedback)] = []

    func saveInsight(_ insight: Insight) async throws {
        _ = insight
    }

    func fetchInsights(limit: Int) async throws -> [Insight] {
        _ = limit
        return []
    }

    func updateFeedback(insightId: UUID, feedback: Insight.UserFeedback) async throws {
        updateCalls.append((insightId, feedback))
    }
}

private final class StubPromptFeedbackOptimizer: PromptFeedbackOptimizing {
    private(set) var recordCalls: [(insight: Insight, feedback: Insight.UserFeedback)] = []

    func recordFeedback(for insight: Insight, feedback: Insight.UserFeedback) {
        recordCalls.append((insight, feedback))
    }
}
