// MARK: - Presentation.ViewModels

import Foundation
import Combine

@MainActor
final class WeeklyMeetingAnalysisViewModel: ObservableObject {
    @Published private(set) var analysis: WeeklyMeetingAnalysis?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let fetchWeeklyMeetingAnalysisUseCase: FetchWeeklyMeetingAnalysisUseCaseProtocol

    init(fetchWeeklyMeetingAnalysisUseCase: FetchWeeklyMeetingAnalysisUseCaseProtocol) {
        self.fetchWeeklyMeetingAnalysisUseCase = fetchWeeklyMeetingAnalysisUseCase
    }

    func load(for date: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }

        do {
            analysis = try await fetchWeeklyMeetingAnalysisUseCase.execute(weekStart: date.startOfWeek)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
