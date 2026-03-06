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
    @Published var statusMessage: String?

    let accountEmail = "user@lifeanalytics.ai"

    private let userDefaultsManager: UserDefaultsManager
    private let notificationService: NotificationServiceProtocol

    init(
        userDefaultsManager: UserDefaultsManager,
        notificationService: NotificationServiceProtocol
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.notificationService = notificationService

        notificationsEnabled = userDefaultsManager.notificationsEnabled
        morningNotificationTime = userDefaultsManager.morningNotificationTime
        eveningNotificationTime = userDefaultsManager.eveningNotificationTime
        weeklyReportEnabled = userDefaultsManager.weeklyReportEnabled
        preferredInsightTone = userDefaultsManager.preferredInsightTone
        preferredTheme = userDefaultsManager.preferredTheme
        healthKitSyncEnabled = userDefaultsManager.healthKitSyncEnabled
        calendarSyncEnabled = userDefaultsManager.calendarSyncEnabled
    }

    func persistNotificationState() async {
        userDefaultsManager.notificationsEnabled = notificationsEnabled
        userDefaultsManager.morningNotificationTime = morningNotificationTime
        userDefaultsManager.eveningNotificationTime = eveningNotificationTime
        userDefaultsManager.weeklyReportEnabled = weeklyReportEnabled

        guard notificationsEnabled else {
            statusMessage = "Bildirimler kapatildi."
            return
        }

        do {
            try await notificationService.requestAuthorization()

            let components = Calendar.current.dateComponents([.hour, .minute], from: morningNotificationTime)
            try await notificationService.scheduleDailyMoodReminder(at: components)

            statusMessage = "Gunluk mood hatirlatmasi kaydedildi."
        } catch {
            statusMessage = "Bildirim ayarlari kaydedilemedi: \(error.localizedDescription)"
        }
    }

    func persistPreferences() {
        userDefaultsManager.preferredInsightTone = preferredInsightTone
        userDefaultsManager.preferredTheme = preferredTheme
        userDefaultsManager.healthKitSyncEnabled = healthKitSyncEnabled
        userDefaultsManager.calendarSyncEnabled = calendarSyncEnabled
        statusMessage = "Tercihler guncellendi."
    }

    func resetOnboardingAndPreferences() {
        userDefaultsManager.hasCompletedOnboarding = false
        statusMessage = "Hesap tercihleri sifirlandi. Onboarding bir sonraki acilista tekrar gosterilir."
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
            "calendarSyncEnabled,\(calendarSyncEnabled)"
        ]

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lifeanalytics-settings-\(UUID().uuidString.prefix(8)).csv")

        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
