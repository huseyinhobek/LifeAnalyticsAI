// MARK: - App

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class DependencyContainer: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext? = nil) {
        if let modelContext {
            self.modelContext = modelContext
        } else {
            self.modelContext = PersistenceController.shared.container.mainContext
        }
    }

    // Repositories
    lazy var sleepRepository: SleepRepositoryProtocol = SleepRepository(modelContext: modelContext)
    lazy var moodRepository: MoodRepositoryProtocol = MoodRepository(modelContext: modelContext)
    lazy var calendarRepository: CalendarRepositoryProtocol = CalendarRepository()
    lazy var insightRepository: InsightRepositoryProtocol = InMemoryInsightRepository()

    // Use Cases
    lazy var fetchSleepDataUseCase: FetchSleepDataUseCaseProtocol = {
        FetchSleepDataUseCase(repository: sleepRepository)
    }()

    lazy var saveMoodEntryUseCase: SaveMoodEntryUseCaseProtocol = {
        SaveMoodEntryUseCase(repository: moodRepository)
    }()

    lazy var fetchCalendarEventsUseCase: FetchCalendarEventsUseCaseProtocol = {
        FetchCalendarEventsUseCase(repository: calendarRepository)
    }()

    lazy var generateInsightUseCase: GenerateInsightUseCaseProtocol = {
        GenerateInsightUseCase(repository: insightRepository)
    }()

    lazy var fetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol = {
        FetchWeeklyReportUseCase(repository: insightRepository)
    }()

    // Services
    lazy var healthKitService: HealthKitServiceProtocol = PlaceholderHealthKitService()
    lazy var calendarService: CalendarServiceProtocol = PlaceholderCalendarService()
    lazy var notificationService: NotificationServiceProtocol = PlaceholderNotificationService()
    lazy var insightEngine: InsightEngineProtocol = PlaceholderInsightEngine()
}

private actor InMemorySleepRepository: SleepRepositoryProtocol {
    private var records: [SleepRecord] = []

    func fetchSleepRecords(from: Date, to: Date) async throws -> [SleepRecord] {
        records.filter { $0.date >= from && $0.date <= to }
    }

    func saveSleepRecord(_ record: SleepRecord) async throws {
        records.append(record)
    }

    func getAverageSleep(days: Int) async throws -> Double {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -max(days, 1), to: end) ?? end
        let selected = records.filter { $0.date >= start && $0.date <= end }
        guard !selected.isEmpty else { return 0 }
        let total = selected.reduce(0) { $0 + $1.totalHours }
        return total / Double(selected.count)
    }
}

private actor InMemoryMoodRepository: MoodRepositoryProtocol {
    private var entries: [MoodEntry] = []

    func saveMoodEntry(_ entry: MoodEntry) async throws {
        entries.append(entry)
    }

    func fetchMoodEntries(from: Date, to: Date) async throws -> [MoodEntry] {
        entries.filter { $0.timestamp >= from && $0.timestamp <= to }
    }

    func getAverageMood(days: Int) async throws -> Double {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -max(days, 1), to: end) ?? end
        let selected = entries.filter { $0.timestamp >= start && $0.timestamp <= end }
        guard !selected.isEmpty else { return 0 }
        let total = selected.reduce(0) { $0 + Double($1.value) }
        return total / Double(selected.count)
    }
}

private actor InMemoryCalendarRepository: CalendarRepositoryProtocol {
    private var events: [CalendarEvent] = []

    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent] {
        events.filter { $0.startDate >= from && $0.endDate <= to }
    }

    func getDailySummary(for date: Date) async throws -> DailySummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let dayEvents = events.filter { $0.startDate >= startOfDay && $0.startDate < endOfDay && $0.isMeeting }
        let meetingMinutes = dayEvents.reduce(0) { $0 + $1.durationMinutes }
        let freeHours = max(0, 24 - (Double(meetingMinutes) / 60.0))

        let busiestHour: Int? = dayEvents
            .compactMap { calendar.dateComponents([.hour], from: $0.startDate).hour }
            .reduce(into: [:]) { counts, hour in counts[hour, default: 0] += 1 }
            .max(by: { $0.value < $1.value })?
            .key

        return DailySummary(
            date: startOfDay,
            totalMeetings: dayEvents.count,
            totalMeetingMinutes: meetingMinutes,
            freeHours: freeHours,
            busiestHour: busiestHour
        )
    }
}

private actor InMemoryInsightRepository: InsightRepositoryProtocol {
    private var insights: [Insight] = []

    func saveInsight(_ insight: Insight) async throws {
        insights.append(insight)
    }

    func fetchInsights(limit: Int) async throws -> [Insight] {
        Array(insights.suffix(max(limit, 0))).reversed()
    }

    func updateFeedback(insightId: UUID, feedback: Insight.UserFeedback) async throws {
        guard let index = insights.firstIndex(where: { $0.id == insightId }) else { return }
        insights[index].userFeedback = feedback
    }
}

private struct PlaceholderHealthKitService: HealthKitServiceProtocol {
    func requestAuthorization() async throws {}
}

private struct PlaceholderCalendarService: CalendarServiceProtocol {
    func requestAccess() async throws {}
}

private struct PlaceholderNotificationService: NotificationServiceProtocol {
    func requestAuthorization() async throws {}
}

private struct PlaceholderInsightEngine: InsightEngineProtocol {
    func generateInsights() async throws -> [Insight] {
        []
    }
}
