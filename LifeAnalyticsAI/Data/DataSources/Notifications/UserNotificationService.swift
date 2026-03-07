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
        content.title = "notification.morning.title".localized
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
        content.title = "notification.evening.title".localized
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
        content.title = "notification.weekly.title".localized
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
        let fallback = "notification.morning.fallback".localized(with: max(streakDays, 1))
        guard let predictionText, !predictionText.isEmpty else {
            return fallback
        }

        let containsNumber = predictionText.contains { $0.isNumber }
        if containsNumber {
            return predictionText
        }

        return "notification.morning.suffix".localized(with: predictionText)
    }

    static func eveningBody(moodCheckInsThisWeek: Int) -> String {
        let safeCheckIns = min(max(moodCheckInsThisWeek, 0), 7)
        return "notification.evening.body".localized(with: safeCheckIns)
    }

    static func weeklyBody(trackedDays: Int) -> String {
        let safeTrackedDays = max(trackedDays, 0)
        return "notification.weekly.body".localized(with: safeTrackedDays)
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
