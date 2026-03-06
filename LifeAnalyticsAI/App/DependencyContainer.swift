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
    lazy var calendarRepository: CalendarRepositoryProtocol = CalendarRepository(calendarService: calendarService)
    lazy var insightRepository: InsightRepositoryProtocol = InsightRepository(modelContext: modelContext)

    // Use Cases
    lazy var fetchSleepDataUseCase: FetchSleepDataUseCaseProtocol = {
        FetchSleepDataUseCase(repository: sleepRepository)
    }()

    lazy var saveMoodEntryUseCase: SaveMoodEntryUseCaseProtocol = {
        SaveMoodEntryUseCase(repository: moodRepository)
    }()

    lazy var fetchMoodEntriesUseCase: FetchMoodEntriesUseCaseProtocol = {
        FetchMoodEntriesUseCase(repository: moodRepository)
    }()

    lazy var fetchCalendarEventsUseCase: FetchCalendarEventsUseCaseProtocol = {
        FetchCalendarEventsUseCase(repository: calendarRepository)
    }()

    lazy var fetchWeeklyMeetingAnalysisUseCase: FetchWeeklyMeetingAnalysisUseCaseProtocol = {
        FetchWeeklyMeetingAnalysisUseCase(repository: calendarRepository)
    }()

    lazy var syncCalendarEventsUseCase: SyncCalendarEventsUseCaseProtocol = {
        SyncCalendarEventsUseCase(calendarSyncManager: calendarSyncManager)
    }()

    lazy var generateInsightUseCase: GenerateInsightUseCaseProtocol = {
        GenerateInsightUseCase(repository: insightRepository)
    }()

    lazy var fetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol = {
        FetchWeeklyReportUseCase(repository: insightRepository)
    }()

    lazy var sleepStatisticsCalculator: SleepStatisticsCalculator = {
        SleepStatisticsCalculator(repository: sleepRepository)
    }()

    lazy var moodStatisticsCalculator: MoodStatisticsCalculator = {
        MoodStatisticsCalculator(repository: moodRepository)
    }()

    // Services
    lazy var healthKitService: HealthKitServiceProtocol = HealthKitService()
    lazy var calendarService: CalendarServiceProtocol = EventKitCalendarService()
    lazy var notificationService: NotificationServiceProtocol = UserNotificationService()
    lazy var insightEngine: InsightEngineProtocol = PlaceholderInsightEngine()

    // Sync Managers
    lazy var healthKitSyncManager: HealthKitSyncManager = {
        HealthKitSyncManager(
            healthKitService: healthKitService,
            sleepRepository: sleepRepository
        )
    }()

    lazy var calendarSyncManager: CalendarSyncManager = {
        CalendarSyncManager(calendarRepository: calendarRepository)
    }()
}

private struct PlaceholderNotificationService: NotificationServiceProtocol {
    func requestAuthorization() async throws {}

    func scheduleDailyMoodReminder(at components: DateComponents) async throws {
        _ = components
    }
}

private struct PlaceholderInsightEngine: InsightEngineProtocol {
    func analyzeCorrelations() async throws -> [Insight] {
        []
    }

    func detectAnomalies() async throws -> [Insight] {
        []
    }

    func findSeasonality() async throws -> [Insight] {
        []
    }

    func generateDailyInsight(for date: Date) async throws -> Insight? {
        _ = date
        return nil
    }

    func generateWeeklyReport(for weekStart: Date) async throws -> WeeklyReport {
        _ = weekStart
        return WeeklyReport(
            id: UUID(),
            weekStartDate: Date().startOfWeek,
            summary: "Haftalik rapor placeholder",
            insights: [],
            keyMetrics: [],
            prediction: nil
        )
    }

}
