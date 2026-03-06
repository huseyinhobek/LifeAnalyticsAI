// MARK: - Domain.UseCases

import Foundation

enum MoodTrendDirection {
    case up
    case down
    case stable
}

struct MoodTrendResult {
    let direction: MoodTrendDirection
    let weeklyChange: Double
}

struct MoodBestDayProfile {
    let weekday: Int
    let averageMood: Double
    let topActivities: [ActivityTag]
}

struct MoodWeekdayWeekendDifference {
    let weekdayAverage: Double
    let weekendAverage: Double
    let difference: Double
}

final class MoodStatisticsCalculator {
    private let repository: MoodRepositoryProtocol

    init(repository: MoodRepositoryProtocol) {
        self.repository = repository
    }

    func averageMood(days: Int) async throws -> Double {
        let entries = try await entriesForLastDays(days)
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + Double($1.value) }
        return total / Double(entries.count)
    }

    func moodTrend(weeks: Int) async throws -> MoodTrendResult {
        let totalDays = max(weeks, 1) * 7
        let entries = try await entriesForLastDays(totalDays).sorted { $0.timestamp < $1.timestamp }
        guard entries.count >= 2 else {
            return MoodTrendResult(direction: .stable, weeklyChange: 0)
        }

        let splitIndex = max(1, entries.count / 2)
        let early = entries.prefix(splitIndex)
        let recent = entries.suffix(entries.count - splitIndex)

        let earlyAverage = early.reduce(0) { $0 + Double($1.value) } / Double(early.count)
        let recentAverage = recent.reduce(0) { $0 + Double($1.value) } / Double(max(recent.count, 1))
        let rawChange = recentAverage - earlyAverage
        let weeklyChange = rawChange / Double(max(weeks, 1))

        let direction: MoodTrendDirection
        if weeklyChange > 0.08 {
            direction = .up
        } else if weeklyChange < -0.08 {
            direction = .down
        } else {
            direction = .stable
        }

        return MoodTrendResult(direction: direction, weeklyChange: weeklyChange)
    }

    func bestDayProfile(days: Int) async throws -> MoodBestDayProfile? {
        let entries = try await entriesForLastDays(days)
        guard !entries.isEmpty else { return nil }

        let grouped = Dictionary(grouping: entries) { Calendar.current.component(.weekday, from: $0.date) }
        guard let best = grouped.max(by: { average(of: $0.value) < average(of: $1.value) }) else {
            return nil
        }

        let activityCounts = best.value
            .flatMap(\.activities)
            .reduce(into: [ActivityTag: Int]()) { counts, tag in
                counts[tag, default: 0] += 1
            }

        let topActivities = activityCounts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.rawValue < rhs.key.rawValue
                }
                return lhs.value > rhs.value
            }
            .prefix(3)
            .map(\.key)

        return MoodBestDayProfile(
            weekday: best.key,
            averageMood: average(of: best.value),
            topActivities: Array(topActivities)
        )
    }

    func weekdayWeekendDifference(days: Int) async throws -> MoodWeekdayWeekendDifference {
        let entries = try await entriesForLastDays(days)
        guard !entries.isEmpty else {
            return MoodWeekdayWeekendDifference(weekdayAverage: 0, weekendAverage: 0, difference: 0)
        }

        let weekdayEntries = entries.filter { !Calendar.current.isDateInWeekend($0.date) }
        let weekendEntries = entries.filter { Calendar.current.isDateInWeekend($0.date) }

        let weekdayAverage = average(of: weekdayEntries)
        let weekendAverage = average(of: weekendEntries)

        return MoodWeekdayWeekendDifference(
            weekdayAverage: weekdayAverage,
            weekendAverage: weekendAverage,
            difference: weekendAverage - weekdayAverage
        )
    }

    private func entriesForLastDays(_ days: Int) async throws -> [MoodEntry] {
        let safeDays = max(days, 1)
        let to = Date()
        let from = to.daysAgo(safeDays)
        return try await repository.fetchMoodEntries(from: from, to: to)
    }

    private func average(of entries: [MoodEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + Double($1.value) }
        return total / Double(entries.count)
    }
}
