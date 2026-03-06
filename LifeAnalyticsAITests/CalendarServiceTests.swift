// MARK: - Tests.CalendarService

import XCTest
@testable import LifeAnalyticsAI

final class CalendarServiceTests: XCTestCase {
    func testEventParsingSortsAndAppliesFallbackTitle() async throws {
        let service = MockCalendarService()
        let base = Date().startOfDay
        service.rawEvents = [
            .init(title: "Planning", startDate: base.addingTimeInterval(3600 * 14), endDate: base.addingTimeInterval(3600 * 15), isAllDay: false, calendarName: "Work"),
            .init(title: nil, startDate: base.addingTimeInterval(3600 * 9), endDate: base.addingTimeInterval(3600 * 10), isAllDay: false, calendarName: "Work"),
            .init(title: "Out of range", startDate: base.addingTimeInterval(3600 * 40), endDate: base.addingTimeInterval(3600 * 41), isAllDay: false, calendarName: "Work")
        ]

        let events = try await service.fetchEvents(from: base, to: base.endOfDay)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.title, "Untitled Event")
        XCTAssertTrue((events.first?.startDate ?? .distantFuture) < (events.last?.startDate ?? .distantPast))
    }

    func testDailySummaryCalculatesMeetingTotals() async throws {
        let service = MockCalendarService()
        let base = Date().startOfDay
        service.rawEvents = [
            .init(title: "Standup", startDate: base.addingTimeInterval(3600 * 9), endDate: base.addingTimeInterval(3600 * 9.5), isAllDay: false, calendarName: "Work"),
            .init(title: "Quick Ping", startDate: base.addingTimeInterval(3600 * 11), endDate: base.addingTimeInterval(3600 * 11 + 600), isAllDay: false, calendarName: "Work"),
            .init(title: "Retro", startDate: base.addingTimeInterval(3600 * 9 + 1800), endDate: base.addingTimeInterval(3600 * 10 + 1800), isAllDay: false, calendarName: "Work")
        ]

        let summary = try await service.getDailySummary(for: base)

        XCTAssertEqual(summary.totalMeetings, 2)
        XCTAssertEqual(summary.totalMeetingMinutes, 90)
        XCTAssertEqual(summary.busiestHour, 9)
        XCTAssertEqual(summary.freeHours, 22.5, accuracy: 0.01)
    }

    func testWeeklyAnalysisComparesWithPreviousWeek() async throws {
        let service = MockCalendarService()
        let thisWeekStart = Date().startOfWeek
        let previousWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: thisWeekStart) ?? thisWeekStart

        service.rawEvents = [
            .init(title: "Current A", startDate: thisWeekStart.addingTimeInterval(3600 * 10), endDate: thisWeekStart.addingTimeInterval(3600 * 11), isAllDay: false, calendarName: "Work"),
            .init(title: "Current B", startDate: thisWeekStart.addingTimeInterval(3600 * 24 + 3600 * 14), endDate: thisWeekStart.addingTimeInterval(3600 * 24 + 3600 * 15), isAllDay: false, calendarName: "Work"),
            .init(title: "Previous", startDate: previousWeekStart.addingTimeInterval(3600 * 24 + 3600 * 10), endDate: previousWeekStart.addingTimeInterval(3600 * 24 + 3600 * 11), isAllDay: false, calendarName: "Work")
        ]

        let analysis = try await service.getWeeklyMeetingAnalysis(for: thisWeekStart)

        XCTAssertEqual(analysis.totalMeetings, 2)
        XCTAssertEqual(analysis.previousWeekMeetings, 1)
        XCTAssertEqual(analysis.weekOverWeekChange, 1)
    }
}
