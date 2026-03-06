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
        let start = date.startOfDay
        let end = date.endOfDay

        let events = try await fetchEvents(from: start, to: end)
        let meetings = events.filter { $0.isMeeting }

        let totalMeetingMinutes = meetings.reduce(0) { $0 + $1.durationMinutes }
        let freeHours = max(0, 24 - (Double(totalMeetingMinutes) / 60.0))
        let busiestHour = meetings
            .map { Calendar.current.component(.hour, from: $0.startDate) }
            .reduce(into: [:]) { counts, hour in
                counts[hour, default: 0] += 1
            }
            .max(by: { $0.value < $1.value })?
            .key

        return DailySummary(
            date: start,
            totalMeetings: meetings.count,
            totalMeetingMinutes: totalMeetingMinutes,
            freeHours: freeHours,
            busiestHour: busiestHour
        )
    }
}
