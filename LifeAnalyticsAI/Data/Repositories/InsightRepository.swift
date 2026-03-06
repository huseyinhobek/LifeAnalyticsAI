// MARK: - Data.Repositories

import Foundation
import SwiftData

final class InsightRepository: InsightRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveInsight(_ insight: Insight) async throws {
        var fetchByID = FetchDescriptor<InsightEntity>(
            predicate: #Predicate<InsightEntity> { $0.id == insight.id }
        )
        fetchByID.fetchLimit = 1

        if let existing = try modelContext.fetch(fetchByID).first {
            existing.date = insight.date
            existing.type = insight.type.rawValue
            existing.title = insight.title
            existing.body = insight.body
            existing.confidenceLevel = insight.confidenceLevel.rawValue
            existing.relatedMetricsJSON = encodeMetrics(insight.relatedMetrics)
            existing.userFeedback = insight.userFeedback?.rawValue
        } else {
            let entity = InsightEntity.fromDomain(insight)
            modelContext.insert(entity)
        }

        try modelContext.save()
    }

    func fetchInsights(limit: Int) async throws -> [Insight] {
        var descriptor = FetchDescriptor<InsightEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = max(limit, 0)

        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    func updateFeedback(insightId: UUID, feedback: Insight.UserFeedback) async throws {
        var descriptor = FetchDescriptor<InsightEntity>(
            predicate: #Predicate<InsightEntity> { $0.id == insightId }
        )
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            throw AppError.dataNotFound
        }

        entity.userFeedback = feedback.rawValue
        try modelContext.save()
    }

    private func encodeMetrics(_ metrics: [MetricReference]) -> String {
        guard let data = try? JSONEncoder().encode(metrics),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}
