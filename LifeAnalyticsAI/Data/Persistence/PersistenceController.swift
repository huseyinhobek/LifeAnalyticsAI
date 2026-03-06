// MARK: - Data.Persistence

import Foundation
import SwiftData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([
            SleepRecordEntity.self,
            MoodEntryEntity.self,
            InsightEntity.self,
            WeeklyReportEntity.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer olusturulamadi: \(error.localizedDescription)")
        }
    }

    @MainActor
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.mainContext

        let sample = SleepRecord(
            id: UUID(),
            date: Date(),
            bedtime: Date().addingTimeInterval(-8 * 60 * 60),
            wakeTime: Date(),
            totalMinutes: 480,
            deepSleepMinutes: 90,
            remSleepMinutes: 100,
            lightSleepMinutes: 290,
            efficiency: 0.88,
            source: .manual
        )

        context.insert(SleepRecordEntity.fromDomain(sample))
        try? context.save()

        return controller
    }()
}
