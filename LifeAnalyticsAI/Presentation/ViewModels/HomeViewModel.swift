// MARK: - Presentation.ViewModels

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var todayInsightText = "home.insight_loading".localized
    @Published private(set) var averageSleepHours = 0.0
    @Published private(set) var averageMood = 0.0
    @Published private(set) var todayMeetingCount = 0
    @Published private(set) var weeklyReportSummary: String?
    @Published private(set) var isRefreshing = false
    @Published var errorMessage: String?

    private let generateDailyInsightCardUseCase: GenerateDailyInsightCardUseCaseProtocol
    private let fetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol
    private let sleepRepository: SleepRepositoryProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let calendarRepository: CalendarRepositoryProtocol

    init(
        generateDailyInsightCardUseCase: GenerateDailyInsightCardUseCaseProtocol,
        fetchWeeklyReportUseCase: FetchWeeklyReportUseCaseProtocol,
        sleepRepository: SleepRepositoryProtocol,
        moodRepository: MoodRepositoryProtocol,
        calendarRepository: CalendarRepositoryProtocol
    ) {
        self.generateDailyInsightCardUseCase = generateDailyInsightCardUseCase
        self.fetchWeeklyReportUseCase = fetchWeeklyReportUseCase
        self.sleepRepository = sleepRepository
        self.moodRepository = moodRepository
        self.calendarRepository = calendarRepository
    }

    func load() async {
        if isRefreshing { return }
        await refresh()
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let today = Date()
            let start = today.daysAgo(7)

            async let insightCard = generateDailyInsightCardUseCase.execute(for: today)
            async let weeklyReports = fetchWeeklyReportUseCase.execute(limit: 1)
            async let sleepAverage = sleepRepository.getAverageSleep(days: 7)
            async let moodEntries = moodRepository.fetchMoodEntries(from: start, to: today)
            async let dailySummary = calendarRepository.getDailySummary(for: today)

            let insight = try await insightCard
            let reports = try await weeklyReports
            let sleep = try await sleepAverage
            let moods = try await moodEntries
            let summary = try await dailySummary

            todayInsightText = insight ?? "home.insight_empty".localized
            weeklyReportSummary = reports.first?.summary
            averageSleepHours = sleep
            averageMood = moods.isEmpty ? 0 : moods.map { Double($0.value) }.reduce(0, +) / Double(moods.count)
            todayMeetingCount = summary.totalMeetings
            errorMessage = nil
        } catch {
            if let appError = error as? AppError,
               case .premiumRequired = appError {
                todayInsightText = "premium.free_insight_used".localized
                errorMessage = nil
            } else {
                errorMessage = error.localizedDescription
                if todayInsightText.isEmpty {
                    todayInsightText = "home.insight_failed".localized
                }
            }
        }
    }
}
