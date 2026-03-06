// MARK: - Domain.UseCases

import Foundation

protocol FetchWeeklyReportUseCaseProtocol {
    func execute(limit: Int) async throws -> [WeeklyReport]
}

final class FetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol {
    private let repository: InsightRepositoryProtocol

    init(repository: InsightRepositoryProtocol) {
        self.repository = repository
    }

    func execute(limit: Int = 1) async throws -> [WeeklyReport] {
        let insights = try await repository.fetchInsights(limit: max(limit, 1))

        let report = WeeklyReport(
            id: UUID(),
            weekStartDate: Calendar.current.startOfDay(for: Date()),
            summary: "Haftalik rapor placeholder",
            insights: insights,
            keyMetrics: [],
            prediction: nil
        )

        return [report]
    }
}
