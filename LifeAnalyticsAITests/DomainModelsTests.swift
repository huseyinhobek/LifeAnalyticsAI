// MARK: - Tests.DomainModels

import Foundation
import XCTest
@testable import LifeAnalyticsAI

final class DomainModelsTests: XCTestCase {
    func testCalendarEventDurationAndMeetingClassification() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(60 * 45)
        let event = CalendarEvent(
            id: UUID(),
            title: "Standup",
            startDate: start,
            endDate: end,
            isAllDay: false,
            calendarName: "Work"
        )

        XCTAssertEqual(event.durationMinutes, 45)
        XCTAssertTrue(event.isMeeting)
    }

    func testCalendarEventMeetingClassificationForAllDayEvent() {
        let start = Date(timeIntervalSince1970: 1_700_010_000)
        let end = start.addingTimeInterval(60 * 60)
        let event = CalendarEvent(
            id: UUID(),
            title: "Offsite",
            startDate: start,
            endDate: end,
            isAllDay: true,
            calendarName: "Work"
        )

        XCTAssertFalse(event.isMeeting)
    }

    func testMoodEntryMoodLevelFallsBackToNeutralForInvalidValue() {
        let entry = MoodEntry(
            id: UUID(),
            date: Date(),
            timestamp: Date(),
            value: 99,
            note: nil,
            activities: []
        )

        XCTAssertEqual(entry.moodLevel, .neutral)
    }

    func testSleepRecordTotalHours() {
        let record = SleepRecord(
            id: UUID(),
            date: Date(),
            bedtime: Date(),
            wakeTime: Date().addingTimeInterval(60 * 60 * 8),
            totalMinutes: 480,
            deepSleepMinutes: 90,
            remSleepMinutes: 80,
            lightSleepMinutes: 310,
            efficiency: 0.91,
            source: .healthKit,
            isAboveAverage: nil
        )

        XCTAssertEqual(record.totalHours, 8.0, accuracy: 0.0001)
    }
}
