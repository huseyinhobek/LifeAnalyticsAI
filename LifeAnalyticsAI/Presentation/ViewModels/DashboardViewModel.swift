// MARK: - Presentation.ViewModels

import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    enum TimeWindow: Int, CaseIterable {
        case week = 7
        case twoWeeks = 14
        case month = 30

        var title: String {
            switch self {
            case .week:
                return "7 Gun"
            case .twoWeeks:
                return "14 Gun"
            case .month:
                return "30 Gun"
            }
        }
    }

    struct DataPoint: Identifiable {
        let date: Date
        let value: Double

        var id: Date { date }
    }

    @Published private(set) var sleepPoints: [DataPoint] = []
    @Published private(set) var moodPoints: [DataPoint] = []
    @Published private(set) var activityPoints: [DataPoint] = []
    @Published private(set) var isLoading = false
    @Published var selectedWindow: TimeWindow = .twoWeeks
    @Published var errorMessage: String?

    private let sleepRepository: SleepRepositoryProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let calendarRepository: CalendarRepositoryProtocol

    init(
        sleepRepository: SleepRepositoryProtocol,
        moodRepository: MoodRepositoryProtocol,
        calendarRepository: CalendarRepositoryProtocol
    ) {
        self.sleepRepository = sleepRepository
        self.moodRepository = moodRepository
        self.calendarRepository = calendarRepository
    }

    func load() async {
        if isLoading { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        let endDate = Date().endOfDay
        let startDate = endDate.daysAgo(selectedWindow.rawValue - 1).startOfDay

        do {
            async let sleepRecords = sleepRepository.fetchSleepRecords(from: startDate, to: endDate)
            async let moodEntries = moodRepository.fetchMoodEntries(from: startDate, to: endDate)
            async let events = calendarRepository.fetchEvents(from: startDate, to: endDate)

            let (fetchedSleep, fetchedMood, fetchedEvents) = try await (sleepRecords, moodEntries, events)
            let days = allDays(from: startDate, to: endDate)

            sleepPoints = makeSleepPoints(days: days, records: fetchedSleep)
            moodPoints = makeMoodPoints(days: days, entries: fetchedMood)
            activityPoints = makeActivityPoints(days: days, events: fetchedEvents)
            errorMessage = nil
        } catch {
            sleepPoints = []
            moodPoints = []
            activityPoints = []
            errorMessage = error.localizedDescription
        }
    }

    var averageSleep: Double {
        average(for: sleepPoints)
    }

    var averageMood: Double {
        average(for: moodPoints)
    }

    var totalMeetings: Int {
        Int(activityPoints.reduce(0) { $0 + $1.value })
    }

    private func allDays(from: Date, to: Date) -> [Date] {
        var days: [Date] = []
        var cursor = from.startOfDay

        while cursor <= to {
            days.append(cursor)
            cursor = Calendar.current.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            if let last = days.last, cursor == last {
                break
            }
        }

        return days
    }

    private func makeSleepPoints(days: [Date], records: [SleepRecord]) -> [DataPoint] {
        let grouped = Dictionary(grouping: records) { $0.date.startOfDay }
        return days.map { day in
            let hours = grouped[day, default: []].map(\.totalHours)
            let value = hours.isEmpty ? 0 : hours.reduce(0, +) / Double(hours.count)
            return DataPoint(date: day, value: value)
        }
    }

    private func makeMoodPoints(days: [Date], entries: [MoodEntry]) -> [DataPoint] {
        let grouped = Dictionary(grouping: entries) { $0.date.startOfDay }
        return days.map { day in
            let moods = grouped[day, default: []].map { Double($0.value) }
            let value = moods.isEmpty ? 0 : moods.reduce(0, +) / Double(moods.count)
            return DataPoint(date: day, value: value)
        }
    }

    private func makeActivityPoints(days: [Date], events: [CalendarEvent]) -> [DataPoint] {
        let grouped = Dictionary(grouping: events.filter(\.isMeeting)) { $0.startDate.startOfDay }
        return days.map { day in
            let value = Double(grouped[day, default: []].count)
            return DataPoint(date: day, value: value)
        }
    }

    private func average(for points: [DataPoint]) -> Double {
        let values = points.map(\.value).filter { $0 > 0 }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
