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

    lazy var fetchCalendarEventsUseCase: FetchCalendarEventsUseCaseProtocol = {
        FetchCalendarEventsUseCase(repository: calendarRepository)
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

    // Services
    lazy var healthKitService: HealthKitServiceProtocol = HealthKitService()
    lazy var calendarService: CalendarServiceProtocol = EventKitCalendarService()
    lazy var notificationService: NotificationServiceProtocol = PlaceholderNotificationService()
    lazy var insightEngine: InsightEngineProtocol = PlaceholderInsightEngine()

    // Sync Managers
    lazy var healthKitSyncManager: HealthKitSyncManager = {
        HealthKitSyncManager(
            healthKitService: healthKitService,
            sleepRepository: sleepRepository
        )
    }()
}

private struct PlaceholderNotificationService: NotificationServiceProtocol {
    func requestAuthorization() async throws {}
}

private struct PlaceholderInsightEngine: InsightEngineProtocol {
    func generateInsights() async throws -> [Insight] {
        []
    }
}
