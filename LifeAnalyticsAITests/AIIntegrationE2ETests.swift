// MARK: - Tests.AIIntegrationE2E

import XCTest
@testable import LifeAnalyticsAI

final class AIIntegrationE2ETests: XCTestCase {
    func testRealAPIEndToEndPatternPromptResponseInsight() async throws {
        guard ProcessInfo.processInfo.environment["LAI_ENABLE_REAL_API_TESTS"] == "1" else {
            throw XCTSkip("Set LAI_ENABLE_REAL_API_TESTS=1 to run real API integration tests")
        }

        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Missing ANTHROPIC_API_KEY for real API integration test")
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
        let raw = try await makeRealAnthropicRequest(apiKey: apiKey, userPrompt: template.userPrompt, systemPrompt: template.systemPrompt)
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

    private func makeRealAnthropicRequest(apiKey: String, userPrompt: String, systemPrompt: String) async throws -> Data {
        guard let url = URL(string: AppConstants.API.llmBaseURL) else {
            throw AppError.llmError(message: "Gecersiz LLM URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let body: [String: Any] = [
            "model": AppConstants.API.llmModel,
            "max_tokens": AppConstants.API.maxTokens,
            "messages": [["role": "user", "content": userPrompt]],
            "system": systemPrompt
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AppError.llmError(message: "Real API request failed")
        }

        return data
    }
}
