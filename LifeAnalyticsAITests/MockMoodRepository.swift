// MARK: - Tests.MockMoodRepository

import Foundation
@testable import LifeAnalyticsAI

actor MockMoodRepository: MoodRepositoryProtocol {
    private(set) var entries: [MoodEntry] = []

    func saveMoodEntry(_ entry: MoodEntry) async throws {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
    }

    func fetchMoodEntries(from: Date, to: Date) async throws -> [MoodEntry] {
        entries
            .filter { $0.timestamp >= from && $0.timestamp <= to }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func getAverageMood(days: Int) async throws -> Double {
        let from = Date().daysAgo(days)
        let filtered = entries.filter { $0.timestamp >= from }
        guard !filtered.isEmpty else { return 0 }
        let total = filtered.reduce(0) { $0 + Double($1.value) }
        return total / Double(filtered.count)
    }

    func count() async -> Int { entries.count }
}
