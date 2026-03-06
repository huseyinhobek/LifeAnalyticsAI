// MARK: - Domain.UseCases

import Foundation

protocol FetchWeeklyReportUseCaseProtocol {
    func execute(limit: Int) async throws -> [WeeklyReport]
}

final class FetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol {
    private let repository: InsightRepositoryProtocol
    private let insightEngine: InsightEngineProtocol
    private let llmService: LLMServiceProtocol
    private let predictionTextUseCase: GeneratePredictionTextUseCaseProtocol
    private let languageCodeProvider: @Sendable () -> String

    init(
        repository: InsightRepositoryProtocol,
        insightEngine: InsightEngineProtocol,
        llmService: LLMServiceProtocol,
        predictionTextUseCase: GeneratePredictionTextUseCaseProtocol,
        languageCodeProvider: @escaping @Sendable () -> String = { FetchWeeklyReportUseCase.defaultLanguageCode() }
    ) {
        self.repository = repository
        self.insightEngine = insightEngine
        self.llmService = llmService
        self.predictionTextUseCase = predictionTextUseCase
        self.languageCodeProvider = languageCodeProvider
    }

    func execute(limit: Int = 1) async throws -> [WeeklyReport] {
        let count = max(limit, 1)
        let languageCode = languageCodeProvider()
        var reports: [WeeklyReport] = []
        reports.reserveCapacity(count)

        for index in 0..<count {
            let weekStart = Date().daysAgo(index * 7).startOfWeek
            let report = try await insightEngine.generateWeeklyReport(for: weekStart)
            let aiSummary = await llmService.generateWeeklyReport(report: report, languageCode: languageCode)
            let predictionText = try await predictionTextUseCase.execute(for: weekStart)

            reports.append(
                WeeklyReport(
                    id: report.id,
                    weekStartDate: report.weekStartDate,
                    summary: aiSummary.isEmpty ? report.summary : aiSummary,
                    insights: report.insights,
                    keyMetrics: report.keyMetrics,
                    prediction: predictionText ?? report.prediction
                )
            )
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

    private static func defaultLanguageCode() -> String {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return preferred.hasPrefix("tr") ? "tr" : "en"
    }
}
