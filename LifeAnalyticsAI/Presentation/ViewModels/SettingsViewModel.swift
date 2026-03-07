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
    @Published var anthropicAPIKeyDraft: String
    @Published var requireBiometricForAPIKey: Bool
    @Published var statusMessage: String?

    let accountEmail = "user@lifeanalytics.ai"

    private let userDefaultsManager: UserDefaultsManager
    private let notificationService: NotificationServiceProtocol
    private let generatePredictionTextUseCase: GeneratePredictionTextUseCaseProtocol
    private let secureCredentialStore: SecureCredentialStoreProtocol

    init(
        userDefaultsManager: UserDefaultsManager,
        notificationService: NotificationServiceProtocol,
        generatePredictionTextUseCase: GeneratePredictionTextUseCaseProtocol,
        secureCredentialStore: SecureCredentialStoreProtocol
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.notificationService = notificationService
        self.generatePredictionTextUseCase = generatePredictionTextUseCase
        self.secureCredentialStore = secureCredentialStore

        notificationsEnabled = userDefaultsManager.notificationsEnabled
        morningNotificationTime = userDefaultsManager.morningNotificationTime
        eveningNotificationTime = userDefaultsManager.eveningNotificationTime
        weeklyReportEnabled = userDefaultsManager.weeklyReportEnabled
        preferredInsightTone = userDefaultsManager.preferredInsightTone
        preferredTheme = userDefaultsManager.preferredTheme
        healthKitSyncEnabled = userDefaultsManager.healthKitSyncEnabled
        calendarSyncEnabled = userDefaultsManager.calendarSyncEnabled
        anthropicAPIKeyDraft = ""
        requireBiometricForAPIKey = true
    }

    func persistNotificationState() async {
        userDefaultsManager.notificationsEnabled = notificationsEnabled
        userDefaultsManager.morningNotificationTime = morningNotificationTime
        userDefaultsManager.eveningNotificationTime = eveningNotificationTime
        userDefaultsManager.weeklyReportEnabled = weeklyReportEnabled

        guard notificationsEnabled else {
            await notificationService.cancelAll()
            statusMessage = "Bildirimler kapatildi."
            return
        }

        do {
            let permissionGranted = try await notificationService.requestPermission()
            guard permissionGranted else {
                statusMessage = "Bildirim izni verilmedi. Ayarlardan izin verebilirsin."
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

            statusMessage = "Kisisel bildirim planin optimize edildi. Sabah \(morningHour):30, aksam \(eveningHour):00, haftalik \(weeklyHour):00."
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

    func saveAPIKeyToKeychain() async {
        let trimmed = anthropicAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "API anahtari bos olamaz."
            return
        }

        do {
            try await secureCredentialStore.setAnthropicAPIKey(trimmed, requireBiometric: requireBiometricForAPIKey)
            anthropicAPIKeyDraft = ""
            statusMessage = requireBiometricForAPIKey
                ? "API anahtari Keychain'e kaydedildi ve biyometrik koruma etkinlestirildi."
                : "API anahtari Keychain'e kaydedildi."
        } catch {
            statusMessage = "API anahtari kaydedilemedi: \(error.localizedDescription)"
        }
    }

    func clearAPIKeyFromKeychain() async {
        do {
            try await secureCredentialStore.clearAnthropicAPIKey()
            anthropicAPIKeyDraft = ""
            statusMessage = "API anahtari Keychain'den silindi."
        } catch {
            statusMessage = "API anahtari silinemedi: \(error.localizedDescription)"
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
            "calendarSyncEnabled,\(calendarSyncEnabled)"
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
