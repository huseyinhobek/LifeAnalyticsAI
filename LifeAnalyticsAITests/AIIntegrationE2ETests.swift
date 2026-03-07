// MARK: - Tests.AIIntegrationE2E

import XCTest
@testable import LifeAnalyticsAI

final class AIIntegrationE2ETests: XCTestCase {
    func testRealAPIEndToEndPatternPromptResponseInsight() async throws {
        guard ProcessInfo.processInfo.environment["LAI_ENABLE_REAL_API_TESTS"] == "1" else {
            throw XCTSkip("Set LAI_ENABLE_REAL_API_TESTS=1 to run real API integration tests")
        }

        let insight = Insight(
            id: UUID(),
            date: Date(),
            type: .correlation,
            title: "Uyku ve mood iliskisi",
            body: "Son 14 gunde daha uzun uyku ile daha yuksek mood puani goruldu.",
            confidenceLevel: .high,
            relatedMetrics: [MetricReference(name: "SleepHours", value: 7.8, unit: "saat", trend: .up)],
            userFeedback: nil
        )

        let template = PromptTemplateManager().makeInsightExplanationTemplate(insight: insight, languageCode: "tr")
        let raw = try await makeRealProxyRequest(userPrompt: template.userPrompt, systemPrompt: template.systemPrompt)
        let response = HTTPURLResponse(url: URL(string: AppConstants.API.llmBaseURL)!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let parsed = try LLMResponseParser().parse(data: raw, response: response)

        XCTAssertFalse(parsed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testFallbackStillWorksWhenRequestFails() async {
        let service = AnthropicLLMService(sendRequest: { _, _ in
            throw AppError.networkError(underlying: URLError(.notConnectedToInternet))
        })

        let fallback = await service.generateInsightExplanation(
            insight: Insight(
                id: UUID(),
                date: Date(),
                type: .trend,
                title: "Mood trendi",
                body: "Bu hafta hafif bir artis var.",
                confidenceLevel: .medium,
                relatedMetrics: [],
                userFeedback: nil
            ),
            languageCode: "tr"
        )

        XCTAssertTrue(fallback.contains("Cevrimdisi ozet"))
    }

    private func makeRealProxyRequest(userPrompt: String, systemPrompt: String) async throws -> Data {
        guard let url = URL(string: AppConstants.API.llmBaseURL) else {
            throw AppError.llmError(message: "Gecersiz LLM URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "prompt": userPrompt,
            "system_prompt": systemPrompt,
            "model": AppConstants.API.llmModel,
            "max_tokens": AppConstants.API.maxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AppError.llmError(message: "Real proxy request failed")
        }

        return data
    }
}
