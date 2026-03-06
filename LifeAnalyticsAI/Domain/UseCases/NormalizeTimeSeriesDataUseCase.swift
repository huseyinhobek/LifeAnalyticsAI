// MARK: - Domain.UseCases

import Foundation

protocol NormalizeTimeSeriesDataUseCaseProtocol {
    func execute(
        sleepRecords: [SleepRecord],
        moodEntries: [MoodEntry],
        calendarEvents: [CalendarEvent]
    ) async -> [TimeSeriesDataPoint]

    func normalizeSleepRecords(_ records: [SleepRecord]) async -> [TimeSeriesDataPoint]
    func normalizeMoodEntries(_ entries: [MoodEntry]) async -> [TimeSeriesDataPoint]
    func normalizeCalendarEvents(_ events: [CalendarEvent]) async -> [TimeSeriesDataPoint]
}

final class NormalizeTimeSeriesDataUseCase: NormalizeTimeSeriesDataUseCaseProtocol {
    func execute(
        sleepRecords: [SleepRecord],
        moodEntries: [MoodEntry],
        calendarEvents: [CalendarEvent]
    ) async -> [TimeSeriesDataPoint] {
        async let sleep = normalizeSleepRecords(sleepRecords)
        async let mood = normalizeMoodEntries(moodEntries)
        async let calendar = normalizeCalendarEvents(calendarEvents)

        let merged = await sleep + mood + calendar
        return merged.sorted(by: { $0.date < $1.date })
    }

    func normalizeSleepRecords(_ records: [SleepRecord]) async -> [TimeSeriesDataPoint] {
        records
            .map {
                makePoint(
                    date: $0.date.startOfDay,
                    source: .sleep,
                    metric: .sleepHours,
                    rawValue: $0.totalHours
                )
            }
            .sorted(by: { $0.date < $1.date })
    }

    func normalizeMoodEntries(_ entries: [MoodEntry]) async -> [TimeSeriesDataPoint] {
        entries
            .map {
                makePoint(
                    date: $0.date.startOfDay,
                    source: .mood,
                    metric: .moodScore,
                    rawValue: Double($0.value)
                )
            }
            .sorted(by: { $0.date < $1.date })
    }

    func normalizeCalendarEvents(_ events: [CalendarEvent]) async -> [TimeSeriesDataPoint] {
        guard !events.isEmpty else { return [] }

        let groupedByDay = Dictionary(grouping: events, by: { $0.startDate.startOfDay })
        var points: [TimeSeriesDataPoint] = []
        points.reserveCapacity(groupedByDay.count * 2)

        for (day, dayEvents) in groupedByDay {
            let meetings = dayEvents.filter(\.isMeeting)
            let meetingCount = Double(meetings.count)
            let meetingMinutes = Double(meetings.reduce(0) { $0 + max(0, $1.durationMinutes) })

            points.append(
                makePoint(
                    date: day,
                    source: .calendar,
                    metric: .meetingCount,
                    rawValue: meetingCount
                )
            )
            points.append(
                makePoint(
                    date: day,
                    source: .calendar,
                    metric: .meetingMinutes,
                    rawValue: meetingMinutes
                )
            )
        }

        return points.sorted(by: { $0.date < $1.date })
    }

    private func makePoint(
        date: Date,
        source: TimeSeriesDataPoint.Source,
        metric: TimeSeriesDataPoint.Metric,
        rawValue: Double
    ) -> TimeSeriesDataPoint {
        TimeSeriesDataPoint(
            id: UUID(),
            date: date,
            source: source,
            metric: metric,
            rawValue: rawValue,
            normalizedValue: normalizedValue(rawValue, metric: metric)
        )
    }

    private func normalizedValue(_ rawValue: Double, metric: TimeSeriesDataPoint.Metric) -> Double {
        let range: ClosedRange<Double>

        switch metric {
        case .sleepHours:
            range = 0...12
        case .moodScore:
            range = Double(AppConstants.Mood.scaleMin)...Double(AppConstants.Mood.scaleMax)
        case .meetingCount:
            range = 0...12
        case .meetingMinutes:
            range = 0...720
        }

        guard range.upperBound > range.lowerBound else { return 0 }
        let clamped = min(range.upperBound, max(range.lowerBound, rawValue))
        return (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}
