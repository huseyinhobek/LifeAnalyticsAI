// MARK: - Domain.UseCases

import Foundation

protocol FetchCalendarEventsUseCaseProtocol {
    func execute(from: Date, to: Date) async throws -> [CalendarEvent]
}

final class FetchCalendarEventsUseCase: FetchCalendarEventsUseCaseProtocol {
    private let repository: CalendarRepositoryProtocol

    init(repository: CalendarRepositoryProtocol) {
        self.repository = repository
    }

    func execute(from: Date, to: Date) async throws -> [CalendarEvent] {
        try await repository.fetchEvents(from: from, to: to)
    }
}
