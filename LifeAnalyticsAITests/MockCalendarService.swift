// MARK: - Tests.MockCalendar

import Foundation
@testable import LifeAnalyticsAI

final class MockCalendarService: CalendarServiceProtocol {
    struct RawEvent {
        let title: String?
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
        let calendarName: String?
    }

    var shouldAuthorize = true
    var rawEvents: [RawEvent] = []

    func requestAccess() async throws -> Bool {
        shouldAuthorize
    }

    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent] {
        rawEvents
            .filter { $0.startDate >= from && $0.startDate <= to }
            .sorted { $0.startDate < $1.startDate }
            .map { raw in
                CalendarEvent(
                    id: UUID(),
                    title: raw.title ?? "Untitled Event",
                    startDate: raw.startDate,
                    endDate: raw.endDate,
                    isAllDay: raw.isAllDay,
                    calendarName: raw.calendarName
                )
            }
    }

    func getDailySummary(for date: Date) async throws -> DailySummary {
        let events = try await fetchEvents(from: date.startOfDay, to: date.endOfDay)
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
            date: date.startOfDay,
            totalMeetings: meetings.count,
            totalMeetingMinutes: totalMeetingMinutes,
            freeHours: freeHours,
            busiestHour: busiestHour
        )
    }

    func getWeeklyMeetingAnalysis(for weekStart: Date) async throws -> WeeklyMeetingAnalysis {
        let normalizedStart = weekStart.startOfWeek
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: normalizedStart)?.addingTimeInterval(-1) ?? normalizedStart.endOfDay
        let previousWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: normalizedStart) ?? normalizedStart
        let previousWeekEnd = normalizedStart.addingTimeInterval(-1)

        let current = try await fetchEvents(from: normalizedStart, to: weekEnd).filter { $0.isMeeting }
        let previous = try await fetchEvents(from: previousWeekStart, to: previousWeekEnd).filter { $0.isMeeting }

        let weekdayCounts = current.reduce(into: [Int: Int]()) { counts, event in
            counts[Calendar.current.component(.weekday, from: event.startDate), default: 0] += 1
        }

        return WeeklyMeetingAnalysis(
            weekStart: normalizedStart,
            meetingCountByWeekday: weekdayCounts,
            totalMeetings: current.count,
            totalMeetingMinutes: current.reduce(0) { $0 + $1.durationMinutes },
            previousWeekMeetings: previous.count,
            weekOverWeekChange: current.count - previous.count
        )
    }
}
