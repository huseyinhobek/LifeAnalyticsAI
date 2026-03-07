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
        GenerateInsightUseCase(
            repository: insightRepository,
            insightEngine: insightEngine,
            llmService: llmService
        )
    }()

    lazy var fetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol = {
        FetchWeeklyReportUseCase(
            repository: insightRepository,
            insightEngine: insightEngine,
            llmService: llmService,
            predictionTextUseCase: generatePredictionTextUseCase
        )
    }()

    lazy var generateDailyInsightCardUseCase: GenerateDailyInsightCardUseCaseProtocol = {
        GenerateDailyInsightCardUseCase(
            insightEngine: insightEngine,
            llmService: llmService
        )
    }()

    lazy var generatePredictionTextUseCase: GeneratePredictionTextUseCaseProtocol = {
        GeneratePredictionTextUseCase(
            sleepRepository: sleepRepository,
            moodRepository: moodRepository,
            calendarRepository: calendarRepository,
            llmService: llmService
        )
    }()

    lazy var updateInsightFeedbackUseCase: UpdateInsightFeedbackUseCaseProtocol = {
        UpdateInsightFeedbackUseCase(
            repository: insightRepository,
            promptFeedbackOptimizer: promptTemplateManager
        )
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
    lazy var promptTemplateManager: PromptTemplateManager = PromptTemplateManager()
    lazy var llmService: LLMServiceProtocol = AnthropicLLMService(promptTemplateManager: promptTemplateManager)
    lazy var insightEngine: InsightEngineProtocol = {
        PatternInsightEngine(
            sleepRepository: sleepRepository,
            moodRepository: moodRepository,
            calendarRepository: calendarRepository
        )
    }()

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
    func requestPermission() async throws -> Bool { true }

    func scheduleMorning(at components: DateComponents, streakDays: Int, predictionText: String?) async throws {
        _ = components
        _ = streakDays
        _ = predictionText
    }

    func scheduleEvening(at components: DateComponents, moodCheckInsThisWeek: Int) async throws {
        _ = components
        _ = moodCheckInsThisWeek
    }

    func scheduleWeekly(at components: DateComponents, trackedDays: Int) async throws {
        _ = components
        _ = trackedDays
    }

    func cancelAll() async {
    }
}
