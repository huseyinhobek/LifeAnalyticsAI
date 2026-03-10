// MARK: - Domain.UseCases

import Foundation

enum SleepTrendDirection {
    case up
    case down
    case stable
}

struct SleepTrendResult {
    let direction: SleepTrendDirection
    let weeklyChangeHours: Double
}

final class SleepStatisticsCalculator {
    private let repository: SleepRepositoryProtocol

    init(repository: SleepRepositoryProtocol) {
        self.repository = repository
    }

    func averageDuration(days: Int) async throws -> Double {
        let records = try await recordsForLastDays(days)
        guard !records.isEmpty else { return 0 }

        let totalHours = records.map(\.totalHours).reduce(0, +)
        return totalHours / Double(records.count)
    }

    func sleepTrend(weeks: Int) async throws -> SleepTrendResult {
        let totalDays = max(weeks, 1) * 7
        let records = try await recordsForLastDays(totalDays).sorted(by: { $0.date < $1.date })
        guard records.count >= 2 else {
            return SleepTrendResult(direction: .stable, weeklyChangeHours: 0)
        }

        let startHours = records.first?.totalHours ?? 0
        let endHours = records.last?.totalHours ?? 0
        let rawChange = endHours - startHours
        let weeklyChange = rawChange / Double(max(weeks, 1))

        let direction: SleepTrendDirection
        if weeklyChange > 0.15 {
            direction = .up
        } else if weeklyChange < -0.15 {
            direction = .down
        } else {
            direction = .stable
        }

        return SleepTrendResult(direction: direction, weeklyChangeHours: weeklyChange)
    }

    func bestNight(days: Int) async throws -> SleepRecord? {
        let records = try await recordsForLastDays(days)
        return records.max { lhs, rhs in
            score(for: lhs) < score(for: rhs)
        }
    }

    func worstNight(days: Int) async throws -> SleepRecord? {
        let records = try await recordsForLastDays(days)
        return records.min { lhs, rhs in
            score(for: lhs) < score(for: rhs)
        }
    }

    func averageEfficiency(days: Int) async throws -> Double {
        let records = try await recordsForLastDays(days)
        let efficiencies = records.compactMap(\.efficiency)
        guard !efficiencies.isEmpty else { return 0 }

        let total = efficiencies.reduce(0, +)
        return total / Double(efficiencies.count)
    }

    func bedtimeConsistency(days: Int) async throws -> Double {
        let records = try await recordsForLastDays(days)
        let bedtimesInMinutes = records.map { minutesFromMidnight(for: $0.bedtime) }
        guard bedtimesInMinutes.count >= 2 else { return 0 }

        let mean = bedtimesInMinutes.reduce(0, +) / Double(bedtimesInMinutes.count)
        let variance = bedtimesInMinutes
            .map { pow($0 - mean, 2) }
            .reduce(0, +) / Double(bedtimesInMinutes.count)

        return sqrt(variance)
    }

    private func recordsForLastDays(_ days: Int) async throws -> [SleepRecord] {
        let safeDays = max(days, 1)
        let end = Date()
        let start = end.daysAgo(safeDays)
        return try await repository.fetchSleepRecords(from: start, to: end)
    }

    private func score(for record: SleepRecord) -> Double {
        let hoursScore = record.totalHours
        let efficiencyScore = (record.efficiency ?? 0.75) * 2
        let deepRatio = record.deepSleepMinutes.map { Double($0) / Double(max(record.totalMinutes, 1)) } ?? 0
        let remRatio = record.remSleepMinutes.map { Double($0) / Double(max(record.totalMinutes, 1)) } ?? 0
        let qualityScore = (deepRatio + remRatio) * 3

        return hoursScore + efficiencyScore + qualityScore
    }

    private func minutesFromMidnight(for date: Date) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return Double(hour * 60 + minute)
    }
}
