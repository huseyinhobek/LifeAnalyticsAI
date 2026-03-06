// MARK: - Domain.Repositories

import Foundation

protocol InsightRepositoryProtocol {
    func saveInsight(_ insight: Insight) async throws
    func fetchInsights(limit: Int) async throws -> [Insight]
    func updateFeedback(insightId: UUID, feedback: Insight.UserFeedback) async throws
}
