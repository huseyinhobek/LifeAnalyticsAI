// MARK: - App

import Foundation

#if canImport(UIKit)
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        NotificationCenter.default.addObserver(
            forName: .healthKitSleepDataDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                do {
                    try await self?.handleBackgroundDelivery()
                } catch {
                    AppLogger.health.error("Notification-driven sleep refresh failed: \(error.localizedDescription)")
                }
            }
        }

        return true
    }

    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            do {
                try await handleBackgroundDelivery()
                completionHandler(.newData)
            } catch {
                AppLogger.health.error("Background delivery fetch failed: \(error.localizedDescription)")
                completionHandler(.failed)
            }
        }
    }

    func handleBackgroundDelivery() async throws {
        let service = HealthKitService()
        let end = Date()
        let start = end.daysAgo(2)
        let records = try await service.fetchSleepData(from: start, to: end)
        AppLogger.health.info("Background delivery handled. Sleep records: \(records.count)")
    }
}
#else
final class AppDelegate: NSObject {}
#endif
