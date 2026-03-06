// MARK: - Tests.PatternInsightEngine

import XCTest
@testable import LifeAnalyticsAI

final class PatternInsightEngineTests: XCTestCase {
    func testDetectAnomaliesReturnsMoodOutlierInsight() async throws {
        let targetDate = Date().startOfDay.daysAgo(2)
        let data = makeDataset(days: 30, anomalyDate: targetDate)
        let engine = makeEngine(data: data)

        let insights = try await engine.detectAnomalies()

        XCTAssertFalse(insights.isEmpty)
        XCTAssertTrue(insights.contains { insight in
            insight.type == .anomaly && Calendar.current.isDate(insight.date, inSameDayAs: targetDate)
        })
    }

    func testGenerateDailyInsightPrioritizesAnomalyForSelectedDate() async throws {
        let targetDate = Date().startOfDay.daysAgo(1)
        let data = makeDataset(days: 30, anomalyDate: targetDate)
        let engine = makeEngine(data: data)

        let insight = try await engine.generateDailyInsight(for: targetDate)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.type, .anomaly)
        XCTAssertTrue(Calendar.current.isDate(insight?.date ?? Date.distantPast, inSameDayAs: targetDate))
    }

    func testGenerateWeeklyReportIncludesPredictionAndKeyMetrics() async throws {
        let data = makeDataset(days: 30, anomalyDate: nil)
        let engine = makeEngine(data: data)

        let report = try await engine.generateWeeklyReport(for: Date().startOfWeek)

        XCTAssertEqual(report.weekStartDate, Date().startOfWeek)
        XCTAssertFalse(report.insights.isEmpty)
        XCTAssertNotNil(report.prediction)
        XCTAssertTrue(report.keyMetrics.contains(where: { $0.name == "NextWeekMood" }))
    }

    private func makeEngine(data: Dataset) -> PatternInsightEngine {
        PatternInsightEngine(
            sleepRepository: StubSleepRepository(records: data.sleepRecords),
            moodRepository: StubMoodRepository(entries: data.moodEntries),
            calendarRepository: StubCalendarRepository(events: data.calendarEvents)
        )
    }

    private func makeDataset(days: Int, anomalyDate: Date?) -> Dataset {
        let start = Date().startOfDay.daysAgo(days - 1)
        var sleepRecords: [SleepRecord] = []
        var moodEntries: [MoodEntry] = []
        var calendarEvents: [CalendarEvent] = []

        for dayOffset in 0..<days {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: start) else { continue }
            let sleepHours = 6.5 + (Double(dayOffset) * 0.05)
            let moodValue: Int = {
                if let anomalyDate, Calendar.current.isDate(date, inSameDayAs: anomalyDate) {
                    return 1
                }
                return min(5, max(1, Int((sleepHours - 4.0).rounded())))
            }()

            sleepRecords.append(
                SleepRecord(
                    id: UUID(),
                    date: date,
                    bedtime: date,
                    wakeTime: date.addingTimeInterval(sleepHours * 3600),
                    totalMinutes: Int(sleepHours * 60),
                    deepSleepMinutes: nil,
                    remSleepMinutes: nil,
                    lightSleepMinutes: nil,
                    efficiency: 0.85,
                    source: .manual
                )
            )

            moodEntries.append(
                MoodEntry(
                    id: UUID(),
                    date: date,
                    timestamp: date.addingTimeInterval(20 * 3600),
                    value: moodValue,
                    note: nil,
                    activities: [.work]
                )
            )

            let meetingStart = date.addingTimeInterval(10 * 3600)
            calendarEvents.append(
                CalendarEvent(
                    id: UUID(),
                    title: "Meeting",
                    startDate: meetingStart,
                    endDate: meetingStart.addingTimeInterval(45 * 60),
                    isAllDay: false,
                    calendarName: "Work"
                )
            )
        }

        return Dataset(
            sleepRecords: sleepRecords,
            moodEntries: moodEntries,
            calendarEvents: calendarEvents
        )
    }
}

private struct Dataset {
    let sleepRecords: [SleepRecord]
    let moodEntries: [MoodEntry]
    let calendarEvents: [CalendarEvent]
}

private actor StubSleepRepository: SleepRepositoryProtocol {
    let records: [SleepRecord]

    init(records: [SleepRecord]) {
        self.records = records
    }

    func fetchSleepRecords(from: Date, to: Date) async throws -> [SleepRecord] {
        records.filter { $0.date >= from.startOfDay && $0.date <= to.endOfDay }
    }

    func saveSleepRecord(_ record: SleepRecord) async throws {
        _ = record
    }

    func getAverageSleep(days: Int) async throws -> Double {
        let from = Date().daysAgo(days)
        let selected = records.filter { $0.date >= from.startOfDay }
        guard !selected.isEmpty else { return 0 }
        return selected.map(\.totalHours).reduce(0, +) / Double(selected.count)
    }
}

private actor StubMoodRepository: MoodRepositoryProtocol {
    let entries: [MoodEntry]

    init(entries: [MoodEntry]) {
        self.entries = entries
    }

    func saveMoodEntry(_ entry: MoodEntry) async throws {
        _ = entry
    }

    func fetchMoodEntries(from: Date, to: Date) async throws -> [MoodEntry] {
        entries.filter { $0.timestamp >= from.startOfDay && $0.timestamp <= to.endOfDay }
    }

    func getAverageMood(days: Int) async throws -> Double {
        let from = Date().daysAgo(days)
        let selected = entries.filter { $0.timestamp >= from.startOfDay }
        guard !selected.isEmpty else { return 0 }
        let total = selected.reduce(0) { partialResult, entry in
            partialResult + Double(entry.value)
        }
        return total / Double(selected.count)
    }
}

private actor StubCalendarRepository: CalendarRepositoryProtocol {
    let events: [CalendarEvent]

    init(events: [CalendarEvent]) {
        self.events = events
    }

    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent] {
        events.filter { $0.startDate >= from.startOfDay && $0.startDate <= to.endOfDay }
    }

    func getDailySummary(for date: Date) async throws -> DailySummary {
        _ = date
        return DailySummary(date: Date().startOfDay, totalMeetings: 0, totalMeetingMinutes: 0, freeHours: 0, busiestHour: nil)
    }

    func getWeeklyMeetingAnalysis(for weekStart: Date) async throws -> WeeklyMeetingAnalysis {
        WeeklyMeetingAnalysis(
            weekStart: weekStart.startOfWeek,
            meetingCountByWeekday: [:],
            totalMeetings: 0,
            totalMeetingMinutes: 0,
            previousWeekMeetings: 0,
            weekOverWeekChange: 0
        )
    }
}
