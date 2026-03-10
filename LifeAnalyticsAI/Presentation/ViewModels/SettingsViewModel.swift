// MARK: - Presentation.ViewModels

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool
    @Published var morningNotificationTime: Date
    @Published var eveningNotificationTime: Date
    @Published var weeklyReportEnabled: Bool
    @Published var preferredInsightTone: UserDefaultsManager.InsightTone
    @Published var preferredTheme: UserDefaultsManager.AppTheme
    @Published var healthKitSyncEnabled: Bool
    @Published var calendarSyncEnabled: Bool
    @Published var appLockEnabled: Bool
    @Published var securityAuditResults: [SecurityAuditCheck]
    @Published var statusMessage: String?

    let accountEmail = "user@lifeanalytics.ai"

    private let userDefaultsManager: UserDefaultsManager
    private let notificationService: NotificationServiceProtocol
    private let generatePredictionTextUseCase: GeneratePredictionTextUseCaseProtocol

    init(
        userDefaultsManager: UserDefaultsManager,
        notificationService: NotificationServiceProtocol,
        generatePredictionTextUseCase: GeneratePredictionTextUseCaseProtocol
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.notificationService = notificationService
        self.generatePredictionTextUseCase = generatePredictionTextUseCase

        notificationsEnabled = userDefaultsManager.notificationsEnabled
        morningNotificationTime = userDefaultsManager.morningNotificationTime
        eveningNotificationTime = userDefaultsManager.eveningNotificationTime
        weeklyReportEnabled = userDefaultsManager.weeklyReportEnabled
        preferredInsightTone = userDefaultsManager.preferredInsightTone
        preferredTheme = userDefaultsManager.preferredTheme
        healthKitSyncEnabled = userDefaultsManager.healthKitSyncEnabled
        calendarSyncEnabled = userDefaultsManager.calendarSyncEnabled
        appLockEnabled = userDefaultsManager.appLockEnabled
        securityAuditResults = []
    }

    func persistNotificationState() async {
        userDefaultsManager.notificationsEnabled = notificationsEnabled
        userDefaultsManager.morningNotificationTime = morningNotificationTime
        userDefaultsManager.eveningNotificationTime = eveningNotificationTime
        userDefaultsManager.weeklyReportEnabled = weeklyReportEnabled

        guard notificationsEnabled else {
            await notificationService.cancelAll()
            statusMessage = "settings.status.notifications_disabled".localized
            return
        }

        do {
            let permissionGranted = try await notificationService.requestPermission()
            guard permissionGranted else {
                statusMessage = "settings.status.permission_denied".localized
                return
            }

            await notificationService.cancelAll()

            let trackedDays = trackedDaysSinceOnboarding()
            let predictionText = try await generatePredictionTextUseCase.execute(for: Date())

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
            try await notificationService.scheduleMorning(
                at: morningComponents,
                streakDays: trackedDays,
                predictionText: predictionText
            )

            var eveningComponents = DateComponents()
            eveningComponents.hour = eveningHour
            eveningComponents.minute = AppConstants.Notifications.eveningMinute
            let moodCheckIns = min(max(trackedDays % 8, 1), 7)
            try await notificationService.scheduleEvening(at: eveningComponents, moodCheckInsThisWeek: moodCheckIns)

            if weeklyReportEnabled {
                var weeklyComponents = DateComponents()
                weeklyComponents.weekday = AppConstants.Notifications.weeklyReportDay
                weeklyComponents.hour = weeklyHour
                weeklyComponents.minute = AppConstants.Notifications.weeklyReportMinute
                try await notificationService.scheduleWeekly(at: weeklyComponents, trackedDays: trackedDays)
            }

            statusMessage = "settings.status.notification_plan".localized(with: morningHour, eveningHour, weeklyHour)
        } catch {
            statusMessage = "settings.status.notification_save_failed".localized(with: error.localizedDescription)
        }
    }

    func persistPreferences() {
        userDefaultsManager.preferredInsightTone = preferredInsightTone
        userDefaultsManager.preferredTheme = preferredTheme
        userDefaultsManager.healthKitSyncEnabled = healthKitSyncEnabled
        userDefaultsManager.calendarSyncEnabled = calendarSyncEnabled
        userDefaultsManager.appLockEnabled = appLockEnabled
        statusMessage = "settings.status.preferences_updated".localized
    }

    func resetOnboardingAndPreferences() {
        userDefaultsManager.hasCompletedOnboarding = false
        statusMessage = "settings.status.preferences_reset".localized
    }

    func runSecurityAuditChecklist() {
        let results = SecurityAuditChecklist.run(appLockEnabled: appLockEnabled)
        securityAuditResults = results

        let failedCount = results.filter { $0.status == .failed }.count
        let warningCount = results.filter { $0.status == .warning }.count

        if failedCount > 0 {
            statusMessage = "settings.status.audit_failed".localized(with: failedCount, warningCount)
        } else if warningCount > 0 {
            statusMessage = "settings.status.audit_warning".localized(with: warningCount)
        } else {
            statusMessage = "settings.status.audit_success".localized
        }
    }

    func exportSettingsSnapshot() throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let lines = [
            "LifeAnalyticsAI Settings Snapshot",
            "Olusturma: \(formatter.string(from: Date()))",
            "",
            "notificationsEnabled,\(notificationsEnabled)",
            "morningNotificationTime,\(formatter.string(from: morningNotificationTime))",
            "eveningNotificationTime,\(formatter.string(from: eveningNotificationTime))",
            "weeklyReportEnabled,\(weeklyReportEnabled)",
            "preferredInsightTone,\(preferredInsightTone.rawValue)",
            "preferredTheme,\(preferredTheme.rawValue)",
            "healthKitSyncEnabled,\(healthKitSyncEnabled)",
            "calendarSyncEnabled,\(calendarSyncEnabled)",
            "appLockEnabled,\(appLockEnabled)"
        ]

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lifeanalytics-settings-\(UUID().uuidString.prefix(8)).csv")

        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func trackedDaysSinceOnboarding() -> Int {
        guard let start = userDefaultsManager.dataCollectionStartDate else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(days, 1)
    }
}
