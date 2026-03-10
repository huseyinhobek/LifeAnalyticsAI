// MARK: - Domain.UseCases

import Foundation

protocol UpdateInsightFeedbackUseCaseProtocol {
    func execute(insight: Insight, feedback: Insight.UserFeedback) async throws
}

final class UpdateInsightFeedbackUseCase: UpdateInsightFeedbackUseCaseProtocol {
    private let repository: InsightRepositoryProtocol
    private let promptFeedbackOptimizer: PromptFeedbackOptimizing

    init(
        repository: InsightRepositoryProtocol,
        promptFeedbackOptimizer: PromptFeedbackOptimizing
    ) {
        self.repository = repository
        self.promptFeedbackOptimizer = promptFeedbackOptimizer
    }

    func execute(insight: Insight, feedback: Insight.UserFeedback) async throws {
        try await repository.updateFeedback(insightId: insight.id, feedback: feedback)
        promptFeedbackOptimizer.recordFeedback(for: insight, feedback: feedback)
    }
}
