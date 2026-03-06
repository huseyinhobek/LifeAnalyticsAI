// MARK: - Domain.Models

import Foundation

struct CalendarEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarName: String?

    var durationMinutes: Int {
        Calendar.current.dateComponents([.minute], from: startDate, to: endDate).minute ?? 0
    }

    var isMeeting: Bool {
        !isAllDay && durationMinutes >= 15 && durationMinutes <= 180
    }
}

struct DailySummary: Codable {
    let date: Date
    let totalMeetings: Int
    let totalMeetingMinutes: Int
    let freeHours: Double
    let busiestHour: Int?
}
