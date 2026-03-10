// MARK: - Presentation.ViewModels

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var todayInsightText = "home.insight_loading".localized
    @Published private(set) var averageSleepHours = 0.0
    @Published private(set) var averageMood = 0.0
    @Published private(set) var todayMeetingCount = 0
    @Published private(set) var sleepTrend: [Double] = []
    @Published private(set) var moodTrend: [Double] = []
    @Published private(set) var meetingTrend: [Double] = []
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
            async let sleepRecords = sleepRepository.fetchSleepRecords(from: start, to: today)
            async let moodEntries = moodRepository.fetchMoodEntries(from: start, to: today)
            async let dailySummary = calendarRepository.getDailySummary(for: today)
            async let weeklyEvents = calendarRepository.fetchEvents(from: start, to: today)

            let insight = try await insightCard
            let reports = try await weeklyReports
            let sleep = try await sleepAverage
            let records = try await sleepRecords
            let moods = try await moodEntries
            let summary = try await dailySummary
            let events = try await weeklyEvents

            averageSleepHours = sleep
            averageMood = moods.isEmpty ? 0 : moods.map { Double($0.value) }.reduce(0, +) / Double(moods.count)
            todayMeetingCount = summary.totalMeetings
            todayInsightText = insight ?? fallbackOperationalInsight(for: today, moods: moods, dailySummary: summary)
            weeklyReportSummary = reports.first?.summary
            sleepTrend = trendFromSleep(records, from: start, to: today)
            moodTrend = trendFromMood(moods, from: start, to: today)
            meetingTrend = trendFromMeetings(events, from: start, to: today)
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

    private func trendFromSleep(_ records: [SleepRecord], from: Date, to: Date) -> [Double] {
        let days = dayRange(from: from, to: to)
        let grouped = Dictionary(grouping: records) { $0.date.startOfDay }
        return days.map { day in
            let values = grouped[day, default: []].map(\.totalHours)
            guard !values.isEmpty else { return 0 }
            return values.reduce(0, +) / Double(values.count)
        }
    }

    private func trendFromMood(_ entries: [MoodEntry], from: Date, to: Date) -> [Double] {
        let days = dayRange(from: from, to: to)
        let grouped = Dictionary(grouping: entries) { $0.date.startOfDay }
        return days.map { day in
            let values = grouped[day, default: []].map { Double($0.value) }
            guard !values.isEmpty else { return 0 }
            return values.reduce(0, +) / Double(values.count)
        }
    }

    private func trendFromMeetings(_ events: [CalendarEvent], from: Date, to: Date) -> [Double] {
        let days = dayRange(from: from, to: to)
        let grouped = Dictionary(grouping: events.filter(\.isMeeting)) { $0.startDate.startOfDay }
        return days.map { day in
            Double(grouped[day, default: []].count)
        }
    }

    private func dayRange(from: Date, to: Date) -> [Date] {
        var days: [Date] = []
        var cursor = from.startOfDay

        while cursor <= to.endOfDay {
            days.append(cursor)
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return days
    }

    private func fallbackOperationalInsight(
        for day: Date,
        moods: [MoodEntry],
        dailySummary: DailySummary
    ) -> String {
        let todayMoods = moods.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: day) }
        let avgTodayMood: Double
        if todayMoods.isEmpty {
            avgTodayMood = 0
        } else {
            avgTodayMood = todayMoods.map { Double($0.value) }.reduce(0, +) / Double(todayMoods.count)
        }

        if avgTodayMood > 0 {
            return "home.insight_fallback_with_mood".localized(
                with: dailySummary.totalMeetings,
                avgTodayMood,
                averageSleepHours
            )
        }

        return "home.insight_fallback_no_mood".localized(
            with: dailySummary.totalMeetings,
            averageSleepHours
        )
    }
}
