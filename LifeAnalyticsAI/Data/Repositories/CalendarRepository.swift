// MARK: - Data.Repositories

import Foundation

final class CalendarRepository: CalendarRepositoryProtocol {
    private let calendarService: CalendarServiceProtocol

    init(calendarService: CalendarServiceProtocol) {
        self.calendarService = calendarService
    }

    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent] {
        try await calendarService.fetchEvents(from: from, to: to)
    }

    func getDailySummary(for date: Date) async throws -> DailySummary {
        try await calendarService.getDailySummary(for: date)
    }
}
