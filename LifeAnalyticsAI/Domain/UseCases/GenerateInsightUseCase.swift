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
            return try await repository.fetchInsights(limit: AppConstants.Insights.recentFallbackLimit)
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

        try await persistNewInsights(explainedInsights)

        return explainedInsights
    }

    private func persistNewInsights(_ generatedInsights: [Insight]) async throws {
        guard !generatedInsights.isEmpty else { return }

        var existing = try await repository.fetchInsights(limit: AppConstants.Insights.historyFetchLimit)

        for insight in generatedInsights {
            if isDuplicate(insight, in: existing) {
                continue
            }

            try await repository.saveInsight(insight)
            existing.append(insight)
        }
    }

    private func isDuplicate(_ candidate: Insight, in existing: [Insight]) -> Bool {
        existing.contains { item in
            item.type == candidate.type
                && item.title == candidate.title
                && item.body == candidate.body
                && Calendar.current.isDate(item.date, inSameDayAs: candidate.date)
        }
    }

    private static func defaultLanguageCode() -> String {
        let saved = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite)?.string(forKey: "app_language")
        if let saved, saved.hasPrefix("tr") {
            return "tr"
        }
        return "en"
    }
}
