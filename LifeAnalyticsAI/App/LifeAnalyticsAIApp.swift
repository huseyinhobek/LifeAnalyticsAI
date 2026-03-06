// MARK: - App

import SwiftUI
import SwiftData

@main
struct LifeAnalyticsAIApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    @State private var router = NavigationRouter()
    @State private var userDefaultsManager = UserDefaultsManager()
    @StateObject private var dependencyContainer = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            AppRootView(router: router)
                .environmentObject(dependencyContainer)
                .task {
                    do {
                        _ = try await dependencyContainer.healthKitService.requestAuthorization()
                        try await dependencyContainer.healthKitService.setupBackgroundDelivery()
                        _ = try await dependencyContainer.healthKitSyncManager.syncSleepData()
                        AppLogger.health.info("HealthKit background delivery configured")
                    } catch {
                        AppLogger.health.error("HealthKit authorization failed: \(error.localizedDescription)")
                    }

                    guard userDefaultsManager.notificationsEnabled else { return }

                    do {
                        try await dependencyContainer.notificationService.requestAuthorization()
                        let components = Calendar.current.dateComponents(
                            [.hour, .minute],
                            from: userDefaultsManager.eveningNotificationTime
                        )
                        try await dependencyContainer.notificationService.scheduleDailyMoodReminder(at: components)
                        AppLogger.notification.info("Daily mood reminder scheduled")
                    } catch {
                        AppLogger.notification.error("Mood reminder scheduling failed: \(error.localizedDescription)")
                    }
                }
        }
        .modelContainer(PersistenceController.shared.container)
    }
}
