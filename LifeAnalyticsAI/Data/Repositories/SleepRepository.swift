// MARK: - Data.Repositories

import Foundation
import SwiftData

final class SleepRepository: SleepRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchSleepRecords(from start: Date, to end: Date) async throws -> [SleepRecord] {
        let startDate = start
        let endDate = end

        let predicate = #Predicate<SleepRecordEntity> {
            $0.date >= startDate && $0.date <= endDate
        }

        let descriptor = FetchDescriptor<SleepRecordEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try await MainActor.run {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        }
    }

    func saveSleepRecord(_ record: SleepRecord) async throws {
        try await MainActor.run {
            var fetchByID = FetchDescriptor<SleepRecordEntity>(
                predicate: #Predicate<SleepRecordEntity> { $0.id == record.id }
            )
            fetchByID.fetchLimit = 1

            if let existing = try modelContext.fetch(fetchByID).first {
                existing.date = record.date
                existing.bedtime = record.bedtime
                existing.wakeTime = record.wakeTime
                existing.totalMinutes = record.totalMinutes
                existing.deepSleepMinutes = record.deepSleepMinutes
                existing.remSleepMinutes = record.remSleepMinutes
                existing.efficiency = record.efficiency
                existing.source = record.source.rawValue
            } else {
                let entity = SleepRecordEntity.fromDomain(record)
                modelContext.insert(entity)
            }

            try modelContext.save()
        }
    }

    func getAverageSleep(days: Int) async throws -> Double {
        let records = try await fetchSleepRecords(from: Date().daysAgo(days), to: Date())
        guard !records.isEmpty else { return 0 }
        let sum = records.map(\.totalHours).reduce(0, +)
        return sum / Double(records.count)
    }
}
