// MARK: - Tests.GenerateInsightUseCase

import XCTest
@testable import LifeAnalyticsAI

final class GenerateInsightUseCaseTests: XCTestCase {
    func testExecuteUsesLLMExplanationForGeneratedInsights() async throws {
        let baseInsight = makeInsight(body: "raw-body")
        let useCase = GenerateInsightUseCase(
            repository: StubInsightRepository(storedInsights: []),
            insightEngine: StubInsightEngine(correlations: [baseInsight]),
            llmService: StubLLMService(response: "Natural language explanation"),
            languageCodeProvider: { "en" }
        )

        let result = try await useCase.execute()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.body, "Natural language explanation")
    }

    func testExecuteFallsBackToRepositoryWhenEngineReturnsEmpty() async throws {
        let stored = [makeInsight(body: "stored-insight")]
        let useCase = GenerateInsightUseCase(
            repository: StubInsightRepository(storedInsights: stored),
            insightEngine: StubInsightEngine(correlations: []),
            llmService: StubLLMService(response: "unused"),
            languageCodeProvider: { "tr" }
        )

        let result = try await useCase.execute()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.body, "stored-insight")
    }

    private func makeInsight(body: String) -> Insight {
        Insight(
            id: UUID(),
            date: Date(),
            type: .correlation,
            title: "Insight",
            body: body,
            confidenceLevel: .medium,
            relatedMetrics: [MetricReference(name: "Mood", value: 3.5, unit: "puan", trend: .stable)],
            userFeedback: nil
        )
    }
}

private actor StubInsightRepository: InsightRepositoryProtocol {
    let storedInsights: [Insight]

    init(storedInsights: [Insight]) {
        self.storedInsights = storedInsights
    }

    func saveInsight(_ insight: Insight) async throws {
        _ = insight
    }

    func fetchInsights(limit: Int) async throws -> [Insight] {
        Array(storedInsights.prefix(max(limit, 0)))
    }

    func updateFeedback(insightId: UUID, feedback: Insight.UserFeedback) async throws {
        _ = insightId
        _ = feedback
    }
}

private struct StubInsightEngine: InsightEngineProtocol {
    let correlations: [Insight]

    func analyzeCorrelations() async throws -> [Insight] {
        correlations
    }

    func detectAnomalies() async throws -> [Insight] {
        []
    }

    func findSeasonality() async throws -> [Insight] {
        []
    }

    func generateDailyInsight(for date: Date) async throws -> Insight? {
        _ = date
        return nil
    }

    func generateWeeklyReport(for weekStart: Date) async throws -> WeeklyReport {
        WeeklyReport(
            id: UUID(),
            weekStartDate: weekStart.startOfWeek,
            summary: "stub",
            insights: correlations,
            keyMetrics: [],
            prediction: nil
        )
    }
}

private struct StubLLMService: LLMServiceProtocol {
    let response: String

    func generateInsightExplanation(insight: Insight, languageCode: String) async -> String {
        _ = insight
        _ = languageCode
        return response
    }

    func generateWeeklyReport(report: WeeklyReport, languageCode: String) async -> String {
        _ = report
        _ = languageCode
        return response
    }

    func generatePrediction(prediction: PredictionResult, languageCode: String) async -> String {
        _ = prediction
        _ = languageCode
        return response
    }
}
