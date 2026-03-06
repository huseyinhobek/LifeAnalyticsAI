// MARK: - Domain.UseCases

import Foundation

protocol GenerateInsightUseCaseProtocol {
    func execute() async throws -> [Insight]
}

final class GenerateInsightUseCase: GenerateInsightUseCaseProtocol {
    private let repository: InsightRepositoryProtocol

    init(repository: InsightRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [Insight] {
        try await repository.fetchInsights(limit: 10)
    }
}
