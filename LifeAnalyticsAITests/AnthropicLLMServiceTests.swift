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

        XCTAssertTrue(result.contains("Cevrimdisi haftalik ozet"))
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

        XCTAssertTrue(result.contains("Offline prediction"))
        XCTAssertTrue(result.contains("Confidence"))
    }

    func testGenerateInsightExplanationUsesCacheOnSecondCall() async {
        let counter = RequestCounter()
        let service = AnthropicLLMService(
            sendRequest: { _, _ in
                await counter.increment()
                return "Cached model insight"
            }
        )

        _ = await service.generateInsightExplanation(insight: makeInsight(), languageCode: "tr")
        let second = await service.generateInsightExplanation(insight: makeInsight(), languageCode: "tr")

        XCTAssertEqual(second, "Cached model insight")
        let callCount = await counter.value
        XCTAssertEqual(callCount, 1)
    }

    func testGenerateInsightExplanationFallsBackWhenTokenLimitExceeded() async {
        let suiteName = "tests.llm.limit.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removePersistentDomain(forName: suiteName)

        let tracker = LLMUsageTracker(dailyLimit: 1, monthlyLimit: 1, defaults: defaults)
        let counter = RequestCounter()

        let service = AnthropicLLMService(
            usageTracker: tracker,
            sendRequest: { _, _ in
                await counter.increment()
                return "Should not be called"
            }
        )

        let result = await service.generateInsightExplanation(insight: makeInsight(), languageCode: "tr")

        XCTAssertTrue(result.contains("Cevrimdisi ozet"))
        let callCount = await counter.value
        XCTAssertEqual(callCount, 0)
        defaults?.removePersistentDomain(forName: suiteName)
    }

    func testGenerateInsightExplanationFallsBackWhenRateLimitExceeded() async {
        let suiteName = "tests.llm.rate.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removePersistentDomain(forName: suiteName)

        let limiter = LLMRateLimiter(maxRequestsPerHour: 0, defaults: defaults)
        let counter = RequestCounter()
        let service = AnthropicLLMService(
            rateLimiter: limiter,
            sendRequest: { _, _ in
                await counter.increment()
                return "Should not be called"
            }
        )

        let result = await service.generateInsightExplanation(insight: makeInsight(), languageCode: "en")

        XCTAssertTrue(result.contains("Offline summary"))
        let callCount = await counter.value
        XCTAssertEqual(callCount, 0)
        defaults?.removePersistentDomain(forName: suiteName)
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

private actor RequestCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}
