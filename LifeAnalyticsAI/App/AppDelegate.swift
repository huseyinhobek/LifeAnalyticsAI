// MARK: - App

import Foundation

#if canImport(UIKit)
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        configureNotifications()

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

    private func configureNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let openMoodEntry = UNNotificationAction(
            identifier: AppConstants.Notifications.Action.openMoodEntry,
            title: "Mood Gir",
            options: [.foreground]
        )

        let openReport = UNNotificationAction(
            identifier: AppConstants.Notifications.Action.openReport,
            title: "Raporu Ac",
            options: [.foreground]
        )

        let morningCategory = UNNotificationCategory(
            identifier: AppConstants.Notifications.Category.morning,
            actions: [openMoodEntry],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let eveningCategory = UNNotificationCategory(
            identifier: AppConstants.Notifications.Category.evening,
            actions: [openMoodEntry],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let weeklyCategory = UNNotificationCategory(
            identifier: AppConstants.Notifications.Category.weekly,
            actions: [openReport],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([morningCategory, eveningCategory, weeklyCategory])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        _ = center
        _ = notification
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        _ = center
        let category = response.notification.request.content.categoryIdentifier

        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier, AppConstants.Notifications.Action.openMoodEntry:
            if category == AppConstants.Notifications.Category.weekly {
                openDeepLink(AppConstants.Notifications.DeepLink.report)
            } else {
                openDeepLink(AppConstants.Notifications.DeepLink.moodEntry)
            }
        case AppConstants.Notifications.Action.openReport:
            openDeepLink(AppConstants.Notifications.DeepLink.report)
        default:
            break
        }

        completionHandler()
    }

    private func openDeepLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
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
