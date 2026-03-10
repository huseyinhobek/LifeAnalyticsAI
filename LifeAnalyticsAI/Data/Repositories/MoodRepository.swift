// MARK: - Data.Repositories

import Foundation
import SwiftData

final class MoodRepository: MoodRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveMoodEntry(_ entry: MoodEntry) async throws {
        try await MainActor.run {
            var fetchByID = FetchDescriptor<MoodEntryEntity>(
                predicate: #Predicate<MoodEntryEntity> { $0.id == entry.id }
            )
            fetchByID.fetchLimit = 1

            if let existing = try modelContext.fetch(fetchByID).first {
                existing.date = entry.date
                existing.timestamp = entry.timestamp
                existing.value = entry.value
                existing.note = entry.note
                existing.activitiesJSON = encodeActivities(entry.activities)
            } else {
                let entity = MoodEntryEntity.fromDomain(entry)
                modelContext.insert(entity)
            }

            try modelContext.save()
        }
    }

    func fetchMoodEntries(from: Date, to: Date) async throws -> [MoodEntry] {
        let start = from
        let end = to

        let predicate = #Predicate<MoodEntryEntity> {
            $0.timestamp >= start && $0.timestamp <= end
        }

        let descriptor = FetchDescriptor<MoodEntryEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return try await MainActor.run {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        }
    }

    func getAverageMood(days: Int) async throws -> Double {
        let records = try await fetchMoodEntries(from: Date().daysAgo(days), to: Date())
        guard !records.isEmpty else { return 0 }
        let sum = records.map { Double($0.value) }.reduce(0, +)
        return sum / Double(records.count)
    }

    private func encodeActivities(_ activities: [ActivityTag]) -> String {
        guard let data = try? JSONEncoder().encode(activities),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}
