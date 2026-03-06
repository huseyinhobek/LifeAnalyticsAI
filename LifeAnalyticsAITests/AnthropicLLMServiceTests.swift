// MARK: - Tests.AnthropicLLMService

import XCTest
@testable import LifeAnalyticsAI

final class AnthropicLLMServiceTests: XCTestCase {
    func testGenerateInsightExplanationUsesLLMResponse() async {
        let service = AnthropicLLMService(sendRequest: { prompt, systemPrompt in
            XCTAssertTrue(prompt.contains("Tip:"))
            XCTAssertTrue(systemPrompt.contains("anonymized pattern summaries"))
            return "Model insight"
        })

        let result = await service.generateInsightExplanation(
            insight: makeInsight(),
            languageCode: "tr"
        )

        XCTAssertEqual(result, "Model insight")
    }

    func testGenerateWeeklyReportFallsBackOnFailure() async {
        let service = AnthropicLLMService(sendRequest: { _, _ in
            throw AppError.llmError(message: "offline")
        })

        let result = await service.generateWeeklyReport(
            report: makeWeeklyReport(),
            languageCode: "tr"
        )

        XCTAssertTrue(result.contains("Haftalik ozet"))
        XCTAssertTrue(result.contains("Toplam"))
    }

    func testGeneratePredictionFallsBackInEnglish() async {
        let service = AnthropicLLMService(sendRequest: { _, _ in
            throw AppError.networkError(underlying: URLError(.timedOut))
        })

        let result = await service.generatePrediction(
            prediction: PredictionResult(predictedMoodNextDay: 3.6, predictedMoodNextWeekAverage: 3.8, confidence: .medium),
            languageCode: "en"
        )

        XCTAssertTrue(result.contains("Estimated mood"))
        XCTAssertTrue(result.contains("Confidence"))
    }

    private func makeInsight() -> Insight {
        Insight(
            id: UUID(),
            date: Date(),
            type: .correlation,
            title: "Uyku ve mood iliskisi",
            body: "Daha uzun uyku ile mood artisi gozleniyor.",
            confidenceLevel: .high,
            relatedMetrics: [
                MetricReference(name: "Sleep", value: 7.8, unit: "saat", trend: .up)
            ],
            userFeedback: nil
        )
    }

    private func makeWeeklyReport() -> WeeklyReport {
        WeeklyReport(
            id: UUID(),
            weekStartDate: Date().startOfWeek,
            summary: "Bu hafta stabil bir trend var.",
            insights: [makeInsight()],
            keyMetrics: [MetricReference(name: "NextWeekMood", value: 3.9, unit: "puan", trend: .stable)],
            prediction: "Yarin mood 3.8"
        )
    }
}
