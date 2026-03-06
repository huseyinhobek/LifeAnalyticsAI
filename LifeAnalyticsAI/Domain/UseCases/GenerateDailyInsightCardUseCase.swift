// MARK: - Domain.UseCases

import Foundation

protocol GenerateDailyInsightCardUseCaseProtocol {
    func execute(for date: Date) async throws -> String?
}

final class GenerateDailyInsightCardUseCase: GenerateDailyInsightCardUseCaseProtocol {
    private let insightEngine: InsightEngineProtocol
    private let llmService: LLMServiceProtocol
    private let languageCodeProvider: @Sendable () -> String

    init(
        insightEngine: InsightEngineProtocol,
        llmService: LLMServiceProtocol,
        languageCodeProvider: @escaping @Sendable () -> String = { GenerateDailyInsightCardUseCase.defaultLanguageCode() }
    ) {
        self.insightEngine = insightEngine
        self.llmService = llmService
        self.languageCodeProvider = languageCodeProvider
    }

    func execute(for date: Date = Date()) async throws -> String? {
        guard let insight = try await insightEngine.generateDailyInsight(for: date) else {
            return nil
        }

        let languageCode = languageCodeProvider()
        let explanation = await llmService.generateInsightExplanation(insight: insight, languageCode: languageCode)
        return shortCardMessage(from: explanation)
    }

    private func shortCardMessage(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if let periodIndex = trimmed.firstIndex(of: ".") {
            let firstSentence = String(trimmed[...periodIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if firstSentence.count <= 160 {
                return firstSentence
            }
        }

        if trimmed.count <= 160 {
            return trimmed
        }

        let endIndex = trimmed.index(trimmed.startIndex, offsetBy: 157)
        return String(trimmed[..<endIndex]) + "..."
    }

    private static func defaultLanguageCode() -> String {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return preferred.hasPrefix("tr") ? "tr" : "en"
    }
}
