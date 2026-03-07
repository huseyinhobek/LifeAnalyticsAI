// MARK: - Data.DataSources.AI

import Foundation
import CryptoKit

final class AnthropicLLMService: LLMServiceProtocol {
    private let sendRequest: @Sendable (_ prompt: String, _ systemPrompt: String) async throws -> String
    private let promptTemplateManager: PromptTemplateManager
    private let usageTracker: LLMUsageTracking
    private let rateLimiter: LLMRateLimiting
    private let responseCache: LLMResponseCaching
    private let offlineFallbackProvider: OfflineFallbackGenerating
    private let cacheTTL: TimeInterval
    private let now: @Sendable () -> Date

    init(
        promptTemplateManager: PromptTemplateManager = PromptTemplateManager(),
        usageTracker: LLMUsageTracking = LLMUsageTracker(),
        rateLimiter: LLMRateLimiting = LLMRateLimiter(),
        responseCache: LLMResponseCaching = LLMResponseCache(),
        offlineFallbackProvider: OfflineFallbackGenerating = OfflineInsightTemplateProvider(),
        cacheTTL: TimeInterval = AppConstants.API.llmCacheTTLSeconds,
        now: @escaping @Sendable () -> Date = { Date() },
        sendRequest: @escaping @Sendable (_ prompt: String, _ systemPrompt: String) async throws -> String = { prompt, systemPrompt in
            try await NetworkManager.shared.sendLLMRequest(prompt: prompt, systemPrompt: systemPrompt)
        }
    ) {
        self.promptTemplateManager = promptTemplateManager
        self.usageTracker = usageTracker
        self.rateLimiter = rateLimiter
        self.responseCache = responseCache
        self.offlineFallbackProvider = offlineFallbackProvider
        self.cacheTTL = cacheTTL
        self.now = now
        self.sendRequest = sendRequest
    }

    func generateInsightExplanation(insight: Insight, languageCode: String) async -> String {
        let template = promptTemplateManager.makeInsightExplanationTemplate(insight: insight, languageCode: languageCode)

        do {
            return try await requestWithCostControl(template: template)
        } catch {
            return offlineFallbackProvider.insightText(for: insight, languageCode: languageCode)
        }
    }

    func generateWeeklyReport(report: WeeklyReport, languageCode: String) async -> String {
        let template = promptTemplateManager.makeWeeklyReportTemplate(report: report, languageCode: languageCode)

        do {
            return try await requestWithCostControl(template: template)
        } catch {
            return offlineFallbackProvider.weeklyReportText(for: report, languageCode: languageCode)
        }
    }

    func generatePrediction(prediction: PredictionResult, languageCode: String) async -> String {
        let template = promptTemplateManager.makePredictionTemplate(prediction: prediction, languageCode: languageCode)

        do {
            return try await requestWithCostControl(template: template)
        } catch {
            return offlineFallbackProvider.predictionText(for: prediction, languageCode: languageCode)
        }
    }

    private func requestWithCostControl(template: PromptTemplate) async throws -> String {
        let isProxyAvailable = await MainActor.run { ProxyHealthChecker.shared.isProxyAvailable }
        guard isProxyAvailable else {
            throw AppError.networkError(underlying: URLError(.cannotConnectToHost))
        }

        let currentDate = now()
        let key = cacheKey(for: template)

        if let cached = await responseCache.cachedValue(for: key, now: currentDate) {
            return cached
        }

        let estimatedTokens = estimateTokens(template.userPrompt) + estimateTokens(template.systemPrompt)
        let isAllowedByRateLimit = await rateLimiter.isAllowed(at: currentDate)
        guard isAllowedByRateLimit else {
            throw AppError.llmError(message: "LLM saatlik istek limiti asildi")
        }

        let hasBudget = await usageTracker.canConsume(tokens: estimatedTokens, at: currentDate)
        guard hasBudget else {
            throw AppError.llmError(message: "LLM token limiti asildi")
        }

        let response = try await sendRequest(template.userPrompt, template.systemPrompt)
        await rateLimiter.recordRequest(at: currentDate)
        let actualTokens = estimatedTokens + estimateTokens(response)
        await usageTracker.record(tokens: actualTokens, at: currentDate)
        await responseCache.store(response, for: key, ttl: cacheTTL, now: currentDate)
        return response
    }

    private func cacheKey(for template: PromptTemplate) -> String {
        let raw = "\(template.systemPrompt)|\(template.userPrompt)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func estimateTokens(_ text: String) -> Int {
        guard !text.isEmpty else { return 1 }
        return max(1, text.count / 4)
    }

}
