// MARK: - Domain.UseCases

import Foundation

protocol FetchWeeklyMeetingAnalysisUseCaseProtocol {
    func execute(weekStart: Date) async throws -> WeeklyMeetingAnalysis
}

final class FetchWeeklyMeetingAnalysisUseCase: FetchWeeklyMeetingAnalysisUseCaseProtocol {
    private let repository: CalendarRepositoryProtocol

    init(repository: CalendarRepositoryProtocol) {
        self.repository = repository
    }

    func execute(weekStart: Date) async throws -> WeeklyMeetingAnalysis {
        try await repository.getWeeklyMeetingAnalysis(for: weekStart)
    }
}
