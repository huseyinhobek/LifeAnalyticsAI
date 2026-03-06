// MARK: - Domain.UseCases

import Foundation

protocol GenerateInsightUseCaseProtocol {
    func execute() async throws -> [Insight]
}

final class GenerateInsightUseCase: GenerateInsightUseCaseProtocol {
    private let repository: InsightRepositoryProtocol
    private let insightEngine: InsightEngineProtocol

    init(repository: InsightRepositoryProtocol, insightEngine: InsightEngineProtocol) {
        self.repository = repository
        self.insightEngine = insightEngine
    }

    func execute() async throws -> [Insight] {
        let generated = try await insightEngine.analyzeCorrelations()
            + insightEngine.detectAnomalies()
            + insightEngine.findSeasonality()
        if generated.isEmpty {
            return try await repository.fetchInsights(limit: 10)
        }
        return generated
    }
}
