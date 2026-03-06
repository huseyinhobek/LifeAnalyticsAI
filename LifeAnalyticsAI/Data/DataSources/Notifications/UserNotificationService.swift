// MARK: - Data.DataSources.Notifications

import Foundation

#if canImport(UserNotifications)
import UserNotifications

final class UserNotificationService: NotificationServiceProtocol {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        _ = try await center.requestAuthorization(options: options)
    }

    func scheduleDailyMoodReminder(at components: DateComponents) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Mood hatirlatmasi"
        content.body = "Bugunku mood durumunu kaydetmeyi unutma."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationIdentifiers.dailyMoodReminder,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifiers.dailyMoodReminder])
        try await center.add(request)
    }
}

private enum NotificationIdentifiers {
    static let dailyMoodReminder = "dailyMoodReminder"
}

#else
final class UserNotificationService: NotificationServiceProtocol {
    func requestAuthorization() async throws {}

    func scheduleDailyMoodReminder(at components: DateComponents) async throws {
        _ = components
    }
}
#endif
