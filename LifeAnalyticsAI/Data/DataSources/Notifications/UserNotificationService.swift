// MARK: - Data.DataSources.Notifications

import Foundation

#if canImport(UserNotifications)
import UserNotifications

final class UserNotificationService: NotificationServiceProtocol {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestPermission() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return try await center.requestAuthorization(options: options)
    }

    func scheduleMorning(at components: DateComponents, streakDays: Int, predictionText: String?) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Gunaydin, serini koru"
        content.body = NotificationContentBuilder.morningBody(streakDays: streakDays, predictionText: predictionText)
        content.sound = .default
        content.categoryIdentifier = AppConstants.Notifications.Category.morning

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.Notifications.RequestID.morningReminder,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [AppConstants.Notifications.RequestID.morningReminder])
        try await center.add(request)
        NotificationEngagementTracker.recordScheduled(for: .morning)
    }

    func scheduleEvening(at components: DateComponents, moodCheckInsThisWeek: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Aksam degerlendirme"
        content.body = NotificationContentBuilder.eveningBody(moodCheckInsThisWeek: moodCheckInsThisWeek)
        content.sound = .default
        content.categoryIdentifier = AppConstants.Notifications.Category.evening

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.Notifications.RequestID.eveningReminder,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [AppConstants.Notifications.RequestID.eveningReminder])
        try await center.add(request)
        NotificationEngagementTracker.recordScheduled(for: .evening)
    }

    func scheduleWeekly(at components: DateComponents, trackedDays: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Haftalik rapor bildirimi"
        content.body = NotificationContentBuilder.weeklyBody(trackedDays: trackedDays)
        content.sound = .default
        content.categoryIdentifier = AppConstants.Notifications.Category.weekly

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.Notifications.RequestID.weeklyReminder,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [AppConstants.Notifications.RequestID.weeklyReminder])
        try await center.add(request)
        NotificationEngagementTracker.recordScheduled(for: .weekly)
    }

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }
}

enum NotificationContentBuilder {
    static func morningBody(streakDays: Int, predictionText: String?) -> String {
        let fallback = "Son \(max(streakDays, 1)) gundur kayit yapiyorsun. Takvim ve 7 gunluk patern bazli tahminini gormek icin mood girisi yap."
        guard let predictionText, !predictionText.isEmpty else {
            return fallback
        }

        let containsNumber = predictionText.contains { $0.isNumber }
        if containsNumber {
            return predictionText
        }

        return "\(predictionText) (7 gunluk patern bazli)"
    }

    static func eveningBody(moodCheckInsThisWeek: Int) -> String {
        let safeCheckIns = min(max(moodCheckInsThisWeek, 0), 7)
        return "Bugunun ozeti hazir, ruh halini kaydet. Bu hafta \(safeCheckIns)/7 gun mood kaydin var."
    }

    static func weeklyBody(trackedDays: Int) -> String {
        let safeTrackedDays = max(trackedDays, 0)
        return "Bu haftanin yasam raporun hazir. AI yeni bir patern kesfetti: son \(safeTrackedDays) gunde veri toplandi."
    }
}

#else
final class UserNotificationService: NotificationServiceProtocol {
    func requestPermission() async throws -> Bool { true }

    func scheduleMorning(at components: DateComponents, streakDays: Int, predictionText: String?) async throws {
        _ = components
        _ = streakDays
        _ = predictionText
    }

    func scheduleEvening(at components: DateComponents, moodCheckInsThisWeek: Int) async throws {
        _ = components
        _ = moodCheckInsThisWeek
    }

    func scheduleWeekly(at components: DateComponents, trackedDays: Int) async throws {
        _ = components
        _ = trackedDays
    }

    func cancelAll() async {
    }
}
#endif
