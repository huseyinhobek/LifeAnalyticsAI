// MARK: - Presentation.ViewModels

import Foundation

@MainActor
final class WeeklyReportViewModel: ObservableObject {
    @Published private(set) var reports: [WeeklyReport] = []
    @Published private(set) var selectedReport: WeeklyReport?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let fetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol
    private let fallbackWeekStart: Date

    init(fetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol, weekStart: Date? = nil) {
        self.fetchWeeklyReportUseCase = fetchWeeklyReportUseCase
        self.fallbackWeekStart = (weekStart ?? Date()).startOfWeek
    }

    func load() async {
        if isLoading { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let reports = try await fetchWeeklyReportUseCase.execute(limit: 4)
            self.reports = reports
            self.selectedReport = reports.first(where: { $0.weekStartDate.startOfWeek == fallbackWeekStart }) ?? reports.first
            errorMessage = nil
        } catch {
            self.reports = []
            self.selectedReport = nil
            errorMessage = error.localizedDescription
        }
    }
}
