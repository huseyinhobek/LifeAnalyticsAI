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
    @State private var languageManager = LanguageManager()
    @State private var proxyHealthChecker = ProxyHealthChecker.shared
    @StateObject private var dependencyContainer = DependencyContainer()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAppUnlocked = false
    @State private var isAuthenticatingLock = false
    @State private var lockErrorMessage: String?

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppRootView(router: router)
                    .id(languageManager.currentLanguage.rawValue)
                    .environmentObject(dependencyContainer)
                    .blur(radius: shouldShowAppLock ? 8 : 0)
                    .allowsHitTesting(!shouldShowAppLock)

                if shouldShowAppLock {
                    AppLockOverlayView(
                        isAuthenticating: isAuthenticatingLock,
                        errorMessage: lockErrorMessage,
                        unlockAction: {
                            Task { await authenticateForAppLockIfNeeded() }
                        }
                    )
                }
            }
            .task {
                await proxyHealthChecker.performHealthCheck()
                proxyHealthChecker.startPeriodicCheck()
            }
            .task {
                await authenticateForAppLockIfNeeded()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    Task { await authenticateForAppLockIfNeeded() }
                case .background, .inactive:
                    if userDefaultsManager.appLockEnabled {
                        isAppUnlocked = false
                    }
                @unknown default:
                    break
                }
            }
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
            .environment(proxyHealthChecker)
            .environment(languageManager)
        }
        .modelContainer(PersistenceController.shared.container)
    }

    private var shouldShowAppLock: Bool {
        userDefaultsManager.appLockEnabled && !isAppUnlocked
    }

    @MainActor
    private func authenticateForAppLockIfNeeded() async {
        guard userDefaultsManager.appLockEnabled else {
            isAppUnlocked = true
            lockErrorMessage = nil
            return
        }

        do {
            isAuthenticatingLock = true
            let success = try await BiometricAuthenticator.authenticate(
                reason: "app_lock.auth_reason".localized
            )
            isAppUnlocked = success
            lockErrorMessage = nil
        } catch {
            isAppUnlocked = false
            lockErrorMessage = error.localizedDescription
        }
        isAuthenticatingLock = false
    }

    private func trackedDaysSinceOnboarding() -> Int {
        guard let start = userDefaultsManager.dataCollectionStartDate else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(days, 1)
    }
}

private struct AppLockOverlayView: View {
    let isAuthenticating: Bool
    let errorMessage: String?
    let unlockAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color("PrimaryBlue"))

            Text("app_lock.title".localized)
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("app_lock.subtitle".localized)
                .font(Theme.bodyFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("TextSecondary"))

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.captionFont)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("MoodBad"))
            }

            Button {
                unlockAction()
            } label: {
                HStack {
                    if isAuthenticating {
                        ProgressView().tint(.white)
                    }
                    Text("app_lock.unlock".localized)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryBlue"))
            .disabled(isAuthenticating)
        }
        .padding(24)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .padding(24)
    }
}
