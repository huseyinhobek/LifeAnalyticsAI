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

    // Services
    lazy var healthKitService: HealthKitServiceProtocol = PlaceholderHealthKitService()
    lazy var calendarService: CalendarServiceProtocol = PlaceholderCalendarService()
    lazy var notificationService: NotificationServiceProtocol = PlaceholderNotificationService()
    lazy var insightEngine: InsightEngineProtocol = PlaceholderInsightEngine()
}

private struct PlaceholderHealthKitService: HealthKitServiceProtocol {
    func requestAuthorization() async throws -> Bool { true }

    func isAuthorized() -> Bool { true }

    func fetchSleepData(from: Date, to: Date) async throws -> [SleepRecord] { [] }

    func fetchStepCount(for date: Date) async throws -> Int { 0 }

    func fetchHeartRate(from: Date, to: Date) async throws -> [Double] { [] }

    func setupBackgroundDelivery() async throws {}
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
