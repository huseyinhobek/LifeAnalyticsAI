// MARK: - Tests.CalendarDomainUseCases

import Foundation
import XCTest
@testable import LifeAnalyticsAI

final class CalendarDomainUseCasesTests: XCTestCase {
    func testFetchCalendarEventsUseCaseForwardsRange() async throws {
        let repository = TestCalendarRepository()
        let expected = [makeEvent(title: "Planning", startOffsetHours: -3, durationMinutes: 30)]
        await repository.setEvents(expected)
        let useCase = FetchCalendarEventsUseCase(repository: repository)
        let from = Date().daysAgo(3)
        let to = Date()

        let result = try await useCase.execute(from: from, to: to)

        XCTAssertEqual(result, expected)
        let range = await repository.lastFetchRange
        XCTAssertNotNil(range)
        if let range {
            XCTAssertEqual(range.from.timeIntervalSince1970, from.timeIntervalSince1970, accuracy: 0.001)
            XCTAssertEqual(range.to.timeIntervalSince1970, to.timeIntervalSince1970, accuracy: 0.001)
        }
    }

    func testFetchWeeklyMeetingAnalysisUseCaseReturnsRepositoryValue() async throws {
        let repository = TestCalendarRepository()
        let expected = WeeklyMeetingAnalysis(
            weekStart: Date().startOfWeek,
            meetingCountByWeekday: [2: 3],
            totalMeetings: 9,
            totalMeetingMinutes: 410,
            previousWeekMeetings: 7,
            weekOverWeekChange: 2
        )
        await repository.setWeeklyAnalysis(expected)
        let useCase = FetchWeeklyMeetingAnalysisUseCase(repository: repository)

        let result = try await useCase.execute(weekStart: expected.weekStart)

        XCTAssertEqual(result.totalMeetings, 9)
        XCTAssertEqual(result.weekOverWeekChange, 2)
    }

    func testSyncCalendarEventsUseCaseDelegatesToManager() async throws {
        let repository = TestCalendarRepository()
        await repository.setEvents([
            makeEvent(title: "Standup", startOffsetHours: -1, durationMinutes: 15),
            makeEvent(title: "Retro", startOffsetHours: -2, durationMinutes: 45)
        ])
        let defaults = UserDefaults(suiteName: "CalendarDomainUseCasesTests")!
        defaults.removePersistentDomain(forName: "CalendarDomainUseCasesTests")

        let manager = CalendarSyncManager(calendarRepository: repository, defaults: defaults, now: Date.init)
        let useCase = SyncCalendarEventsUseCase(calendarSyncManager: manager)

        let syncedCount = try await useCase.execute(daysBack: 7)

        XCTAssertEqual(syncedCount, 2)
        XCTAssertEqual(manager.cachedEvents.count, 2)
        XCTAssertNotNil(manager.lastCalendarSyncDate)
    }

    private func makeEvent(title: String, startOffsetHours: Int, durationMinutes: Int) -> CalendarEvent {
        let start = Date().addingTimeInterval(TimeInterval(startOffsetHours * 60 * 60))
        return CalendarEvent(
            id: UUID(),
            title: title,
            startDate: start,
            endDate: start.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            isAllDay: false,
            calendarName: "Work"
        )
    }
}

private actor TestCalendarRepository: CalendarRepositoryProtocol {
    private var events: [CalendarEvent] = []
    private var analysis: WeeklyMeetingAnalysis = WeeklyMeetingAnalysis(
        weekStart: Date().startOfWeek,
        meetingCountByWeekday: [:],
        totalMeetings: 0,
        totalMeetingMinutes: 0,
        previousWeekMeetings: 0,
        weekOverWeekChange: 0
    )
    private(set) var lastFetchRange: (from: Date, to: Date)?

    func setEvents(_ value: [CalendarEvent]) {
        events = value
    }

    func setWeeklyAnalysis(_ value: WeeklyMeetingAnalysis) {
        analysis = value
    }

    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent] {
        lastFetchRange = (from, to)
        return events
    }

    func getDailySummary(for date: Date) async throws -> DailySummary {
        _ = date
        return DailySummary(date: Date(), totalMeetings: events.count, totalMeetingMinutes: events.reduce(0) { $0 + $1.durationMinutes }, freeHours: 0, busiestHour: nil)
    }

    func getWeeklyMeetingAnalysis(for weekStart: Date) async throws -> WeeklyMeetingAnalysis {
        _ = weekStart
        return analysis
    }
}
