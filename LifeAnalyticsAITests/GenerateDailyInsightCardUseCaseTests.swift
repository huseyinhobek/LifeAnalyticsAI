// MARK: - Tests.GenerateDailyInsightCardUseCase

import XCTest
@testable import LifeAnalyticsAI

final class GenerateDailyInsightCardUseCaseTests: XCTestCase {
    func testExecuteReturnsShortenedFirstSentence() async throws {
        let longText = "Bugun enerji seviyen dunde gore daha yuksek. Ayni rutini koruman faydali olabilir."
        let useCase = GenerateDailyInsightCardUseCase(
            insightEngine: StubInsightEngineForDailyCard(insight: makeInsight()),
            llmService: StubLLMServiceForDailyCard(response: longText),
            languageCodeProvider: { "tr" }
        )

        let result = try await useCase.execute(for: Date())

        XCTAssertEqual(result, "Bugun enerji seviyen dunde gore daha yuksek.")
    }

    func testExecuteReturnsNilWhenNoDailyInsight() async throws {
        let useCase = GenerateDailyInsightCardUseCase(
            insightEngine: StubInsightEngineForDailyCard(insight: nil),
            llmService: StubLLMServiceForDailyCard(response: "unused"),
            languageCodeProvider: { "en" }
        )

        let result = try await useCase.execute(for: Date())

        XCTAssertNil(result)
    }

    private func makeInsight() -> Insight {
        Insight(
            id: UUID(),
            date: Date(),
            type: .trend,
            title: "Gunluk trend",
            body: "Raw",
            confidenceLevel: .medium,
            relatedMetrics: [MetricReference(name: "Mood", value: 3.7, unit: "puan", trend: .up)],
            userFeedback: nil
        )
    }
}

private struct StubInsightEngineForDailyCard: InsightEngineProtocol {
    let insight: Insight?

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
        return insight
    }

    func generateWeeklyReport(for weekStart: Date) async throws -> WeeklyReport {
        WeeklyReport(
            id: UUID(),
            weekStartDate: weekStart.startOfWeek,
            summary: "stub",
            insights: [],
            keyMetrics: [],
            prediction: nil
        )
    }
}

private struct StubLLMServiceForDailyCard: LLMServiceProtocol {
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
