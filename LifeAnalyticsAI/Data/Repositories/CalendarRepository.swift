// MARK: - Data.Repositories

import EventKit
import Foundation

final class CalendarRepository: CalendarRepositoryProtocol {
    private let eventStore: EKEventStore

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent] {
        try await ensureCalendarAccess()

        let predicate = eventStore.predicateForEvents(withStart: from, end: to, calendars: nil)
        let events = eventStore.events(matching: predicate)

        return events.map { event in
            CalendarEvent(
                id: UUID(),
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                calendarName: event.calendar.title
            )
        }
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

    private func ensureCalendarAccess() async throws {
        let current = EKEventStore.authorizationStatus(for: .event)

        switch current {
        case .fullAccess, .writeOnly:
            return
        case .notDetermined:
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                guard granted else { throw AppError.calendarAccessDenied }
            } else {
                let granted: Bool = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                    eventStore.requestAccess(to: .event) { accessGranted, error in
                        if let error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(returning: accessGranted)
                    }
                }
                guard granted else { throw AppError.calendarAccessDenied }
            }
        case .denied, .restricted:
            throw AppError.calendarAccessDenied
        @unknown default:
            throw AppError.calendarAccessDenied
        }
    }
}
