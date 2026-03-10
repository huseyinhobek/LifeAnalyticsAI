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

        if !inMemory {
            Self.configureDataProtectionForApplicationSupport()
        }

        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        let resolvedContainer: ModelContainer
        var didLoadPersistentStore = false

        do {
            resolvedContainer = try ModelContainer(for: schema, configurations: [config])
            didLoadPersistentStore = !inMemory
        } catch {
            AppLogger.insight.error("ModelContainer initialization failed, attempting in-memory recovery: \(error.localizedDescription)")

            do {
                let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                resolvedContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                AppLogger.insight.warning("Using in-memory SwiftData store after initialization failure")
            } catch {
                fatalError("ModelContainer tamamen baslatilamadi: \(error.localizedDescription)")
            }
        }

        container = resolvedContainer

        if didLoadPersistentStore {
            Self.applyDataProtectionToPersistenceFiles()
        }
    }

    private static func configureDataProtectionForApplicationSupport() {
        let manager = FileManager.default
        guard let appSupportURL = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        do {
            try manager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            try manager.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: appSupportURL.path
            )
        } catch {
            AppLogger.notification.error("Data protection directory setup failed: \(error.localizedDescription)")
        }
    }

    private static func applyDataProtectionToPersistenceFiles() {
        let manager = FileManager.default
        guard let appSupportURL = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        let defaultStoreCandidates = ["default.store", "default.store-wal", "default.store-shm"]

        for name in defaultStoreCandidates {
            let url = appSupportURL.appendingPathComponent(name)
            guard manager.fileExists(atPath: url.path) else { continue }

            do {
                try manager.setAttributes(
                    [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                    ofItemAtPath: url.path
                )
            } catch {
                AppLogger.notification.error("Data protection apply failed for \(name): \(error.localizedDescription)")
            }
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
