// MARK: - Tests.FetchWeeklyReportUseCase

import XCTest
@testable import LifeAnalyticsAI

final class FetchWeeklyReportUseCaseTests: XCTestCase {
    func testExecuteUsesAIWeeklySummary() async throws {
        let baseReport = makeReport(summary: "engine-summary")
        let useCase = FetchWeeklyReportUseCase(
            repository: StubInsightRepositoryForWeekly(storedInsights: []),
            insightEngine: StubInsightEngineForWeekly(report: baseReport),
            llmService: StubLLMServiceForWeekly(response: "AI weekly summary"),
            languageCodeProvider: { "en" }
        )

        let result = try await useCase.execute(limit: 1)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.summary, "AI weekly summary")
    }

    func testExecuteFallsBackToEngineSummaryWhenAIResponseEmpty() async throws {
        let baseReport = makeReport(summary: "engine-summary")
        let useCase = FetchWeeklyReportUseCase(
            repository: StubInsightRepositoryForWeekly(storedInsights: []),
            insightEngine: StubInsightEngineForWeekly(report: baseReport),
            llmService: StubLLMServiceForWeekly(response: ""),
            languageCodeProvider: { "tr" }
        )

        let result = try await useCase.execute(limit: 1)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.summary, "engine-summary")
    }

    private func makeReport(summary: String) -> WeeklyReport {
        WeeklyReport(
            id: UUID(),
            weekStartDate: Date().startOfWeek,
            summary: summary,
            insights: [],
            keyMetrics: [MetricReference(name: "NextWeekMood", value: 3.9, unit: "puan", trend: .stable)],
            prediction: "Yarin mood 3.8"
        )
    }
}

private actor StubInsightRepositoryForWeekly: InsightRepositoryProtocol {
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

private struct StubInsightEngineForWeekly: InsightEngineProtocol {
    let report: WeeklyReport

    func analyzeCorrelations() async throws -> [Insight] {
        []
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
            id: report.id,
            weekStartDate: weekStart.startOfWeek,
            summary: report.summary,
            insights: report.insights,
            keyMetrics: report.keyMetrics,
            prediction: report.prediction
        )
    }
}

private struct StubLLMServiceForWeekly: LLMServiceProtocol {
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
