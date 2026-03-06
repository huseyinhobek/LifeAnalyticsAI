// MARK: - Domain.UseCases

import Foundation

protocol FetchWeeklyReportUseCaseProtocol {
    func execute(limit: Int) async throws -> [WeeklyReport]
}

final class FetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol {
    private let repository: InsightRepositoryProtocol
    private let insightEngine: InsightEngineProtocol

    init(repository: InsightRepositoryProtocol, insightEngine: InsightEngineProtocol) {
        self.repository = repository
        self.insightEngine = insightEngine
    }

    func execute(limit: Int = 1) async throws -> [WeeklyReport] {
        let count = max(limit, 1)
        var reports: [WeeklyReport] = []
        reports.reserveCapacity(count)

        for index in 0..<count {
            let weekStart = Date().daysAgo(index * 7).startOfWeek
            let report = try await insightEngine.generateWeeklyReport(for: weekStart)
            reports.append(report)
        }

        if reports.isEmpty {
            let insights = try await repository.fetchInsights(limit: count)
            return [
                WeeklyReport(
                    id: UUID(),
                    weekStartDate: Date().startOfWeek,
                    summary: "Haftalik rapor fallback",
                    insights: insights,
                    keyMetrics: [],
                    prediction: nil
                )
            ]
        }

        return reports
    }
}
