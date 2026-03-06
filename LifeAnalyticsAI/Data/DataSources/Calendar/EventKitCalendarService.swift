// MARK: - Data.DataSources.Calendar

import EventKit
import Foundation

final class EventKitCalendarService: CalendarServiceProtocol {
    private let eventStore: EKEventStore

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    func requestAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .fullAccess, .writeOnly:
            return true
        case .notDetermined:
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                guard granted else { throw AppError.calendarAccessDenied }
                return true
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
                return true
            }
        case .denied, .restricted:
            throw AppError.calendarAccessDenied
        @unknown default:
            throw AppError.calendarAccessDenied
        }
    }

    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent] {
        _ = try await requestAccess()

        guard to >= from else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: from, end: to, calendars: nil)
        let events = eventStore.events(matching: predicate)

        return events
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                CalendarEvent(
                    id: UUID(),
                    title: event.title ?? "Untitled Event",
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

    func getWeeklyMeetingAnalysis(for weekStart: Date) async throws -> WeeklyMeetingAnalysis {
        let normalizedWeekStart = weekStart.startOfWeek
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: normalizedWeekStart)?.addingTimeInterval(-1) ?? normalizedWeekStart.endOfDay
        let previousWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: normalizedWeekStart) ?? normalizedWeekStart
        let previousWeekEnd = normalizedWeekStart.addingTimeInterval(-1)

        let currentWeekEvents = try await fetchEvents(from: normalizedWeekStart, to: weekEnd)
        let currentMeetings = currentWeekEvents.filter { $0.isMeeting }

        let previousWeekEvents = try await fetchEvents(from: previousWeekStart, to: previousWeekEnd)
        let previousMeetings = previousWeekEvents.filter { $0.isMeeting }

        let meetingCountByWeekday = currentMeetings.reduce(into: [Int: Int]()) { counts, event in
            let weekday = Calendar.current.component(.weekday, from: event.startDate)
            counts[weekday, default: 0] += 1
        }

        let totalMeetingMinutes = currentMeetings.reduce(0) { $0 + $1.durationMinutes }
        let previousWeekCount = previousMeetings.count

        return WeeklyMeetingAnalysis(
            weekStart: normalizedWeekStart,
            meetingCountByWeekday: meetingCountByWeekday,
            totalMeetings: currentMeetings.count,
            totalMeetingMinutes: totalMeetingMinutes,
            previousWeekMeetings: previousWeekCount,
            weekOverWeekChange: currentMeetings.count - previousWeekCount
        )
    }
}
