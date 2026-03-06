// MARK: - Domain.UseCases

import Foundation

protocol GenerateInsightUseCaseProtocol {
    func execute() async throws -> [Insight]
}

final class GenerateInsightUseCase: GenerateInsightUseCaseProtocol {
    private let repository: InsightRepositoryProtocol
    private let insightEngine: InsightEngineProtocol
    private let llmService: LLMServiceProtocol
    private let languageCodeProvider: @Sendable () -> String

    init(
        repository: InsightRepositoryProtocol,
        insightEngine: InsightEngineProtocol,
        llmService: LLMServiceProtocol,
        languageCodeProvider: @escaping @Sendable () -> String = { GenerateInsightUseCase.defaultLanguageCode() }
    ) {
        self.repository = repository
        self.insightEngine = insightEngine
        self.llmService = llmService
        self.languageCodeProvider = languageCodeProvider
    }

    func execute() async throws -> [Insight] {
        let generated = try await insightEngine.analyzeCorrelations()
            + insightEngine.detectAnomalies()
            + insightEngine.findSeasonality()

        if generated.isEmpty {
            return try await repository.fetchInsights(limit: 10)
        }

        let languageCode = languageCodeProvider()
        var explainedInsights: [Insight] = []
        explainedInsights.reserveCapacity(generated.count)

        for insight in generated {
            let explanation = await llmService.generateInsightExplanation(
                insight: insight,
                languageCode: languageCode
            )

            explainedInsights.append(
                Insight(
                    id: insight.id,
                    date: insight.date,
                    type: insight.type,
                    title: insight.title,
                    body: explanation.isEmpty ? insight.body : explanation,
                    confidenceLevel: insight.confidenceLevel,
                    relatedMetrics: insight.relatedMetrics,
                    userFeedback: insight.userFeedback
                )
            )
        }

        return explainedInsights
    }

    private static func defaultLanguageCode() -> String {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return preferred.hasPrefix("tr") ? "tr" : "en"
    }
}
