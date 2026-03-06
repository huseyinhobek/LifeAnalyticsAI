// MARK: - Domain.UseCases

import Foundation

struct PrioritizedInsight: Identifiable, Hashable {
    let id: UUID
    let insight: Insight
    let priorityScore: Double
}

protocol InsightPrioritizationUseCaseProtocol {
    func execute(insights: [Insight], top: Int) async -> [PrioritizedInsight]
}

final class InsightPrioritizationUseCase: InsightPrioritizationUseCaseProtocol {
    func execute(insights: [Insight], top: Int = 5) async -> [PrioritizedInsight] {
        let prioritized = insights.map { insight in
            let confidenceScore: Double
            switch insight.confidenceLevel {
            case .low:
                confidenceScore = 0.35
            case .medium:
                confidenceScore = 0.65
            case .high:
                confidenceScore = 1.0
            }

            let typeScore: Double
            switch insight.type {
            case .anomaly:
                typeScore = 1.0
            case .prediction:
                typeScore = 0.9
            case .correlation:
                typeScore = 0.8
            case .seasonal:
                typeScore = 0.7
            case .trend:
                typeScore = 0.6
            }

            let recencyDays = max(0, Calendar.current.dateComponents([.day], from: insight.date.startOfDay, to: Date().startOfDay).day ?? 0)
            let recencyScore = max(0.2, 1.0 - (Double(recencyDays) / 14.0))
            let score = (confidenceScore * 0.45) + (typeScore * 0.35) + (recencyScore * 0.20)

            return PrioritizedInsight(id: insight.id, insight: insight, priorityScore: score)
        }

        return prioritized
            .sorted(by: { lhs, rhs in
                if lhs.priorityScore == rhs.priorityScore {
                    return lhs.insight.date > rhs.insight.date
                }
                return lhs.priorityScore > rhs.priorityScore
            })
            .prefix(max(1, top))
            .map { $0 }
    }
}
