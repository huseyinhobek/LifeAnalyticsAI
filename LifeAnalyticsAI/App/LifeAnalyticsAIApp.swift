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
                        let permissionGranted = try await dependencyContainer.notificationService.requestPermission()
                        guard permissionGranted else {
                            AppLogger.notification.info("Notification permission not granted")
                            return
                        }

                        await dependencyContainer.notificationService.cancelAll()

                        let trackedDays = trackedDaysSinceOnboarding()
                        let predictionText = try await dependencyContainer.generatePredictionTextUseCase.execute(for: Date())

                        let morningHour = NotificationTimingOptimizer.optimalHour(
                            for: .morning,
                            fallback: AppConstants.Notifications.morningHour,
                            allowedRange: 6...10
                        )
                        let eveningHour = NotificationTimingOptimizer.optimalHour(
                            for: .evening,
                            fallback: AppConstants.Notifications.eveningHour,
                            allowedRange: 19...22
                        )
                        let weeklyHour = NotificationTimingOptimizer.optimalHour(
                            for: .weekly,
                            fallback: AppConstants.Notifications.weeklyReportHour,
                            allowedRange: 17...21
                        )

                        var morningComponents = DateComponents()
                        morningComponents.hour = morningHour
                        morningComponents.minute = AppConstants.Notifications.morningMinute
                        try await dependencyContainer.notificationService.scheduleMorning(
                            at: morningComponents,
                            streakDays: trackedDays,
                            predictionText: predictionText
                        )

                        var eveningComponents = DateComponents()
                        eveningComponents.hour = eveningHour
                        eveningComponents.minute = AppConstants.Notifications.eveningMinute
                        let moodCheckIns = min(max(trackedDays % 8, 1), 7)
                        try await dependencyContainer.notificationService.scheduleEvening(
                            at: eveningComponents,
                            moodCheckInsThisWeek: moodCheckIns
                        )

                        if userDefaultsManager.weeklyReportEnabled {
                            var weeklyComponents = DateComponents()
                            weeklyComponents.weekday = AppConstants.Notifications.weeklyReportDay
                            weeklyComponents.hour = weeklyHour
                            weeklyComponents.minute = AppConstants.Notifications.weeklyReportMinute
                            try await dependencyContainer.notificationService.scheduleWeekly(
                                at: weeklyComponents,
                                trackedDays: trackedDays
                            )
                        }

                        AppLogger.notification.info("Personalized reminder notifications scheduled")
                    } catch {
                        AppLogger.notification.error("Reminder scheduling failed: \(error.localizedDescription)")
                    }
                }
        }
        .modelContainer(PersistenceController.shared.container)
    }

    private func trackedDaysSinceOnboarding() -> Int {
        guard let start = userDefaultsManager.dataCollectionStartDate else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(days, 1)
    }
}
