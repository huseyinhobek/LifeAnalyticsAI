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
        content.body = morningBody(streakDays: streakDays, predictionText: predictionText)
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
    }

    func scheduleEvening(at components: DateComponents, moodCheckInsThisWeek: Int) async throws {
        let safeCheckIns = min(max(moodCheckInsThisWeek, 0), 7)
        let content = UNMutableNotificationContent()
        content.title = "Aksam degerlendirme"
        content.body = "Bugunun ozeti hazir, ruh halini kaydet. Bu hafta \(safeCheckIns)/7 gun mood kaydin var."
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
    }

    func scheduleWeekly(at components: DateComponents, trackedDays: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Haftalik rapor hazirligi"
        content.body = "Son \(max(trackedDays, 0)) gunde veri topladin. Haftalik raporun icin son mood girisini yap."
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
    }

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    private func morningBody(streakDays: Int, predictionText: String?) -> String {
        let fallback = "Son \(streakDays) gundur kayit yapiyorsun. Takvim ve 7 gunluk patern bazli tahminini gormek icin mood girisi yap."
        guard let predictionText, !predictionText.isEmpty else {
            return fallback
        }

        let containsNumber = predictionText.contains { $0.isNumber }
        if containsNumber {
            return predictionText
        }

        return "\(predictionText) (7 gunluk patern bazli)"
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
