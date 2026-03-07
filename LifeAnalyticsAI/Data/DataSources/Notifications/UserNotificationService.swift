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

    func scheduleMorning(at components: DateComponents, streakDays: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Gunaydin, serini koru"
        content.body = "Son \(streakDays) gundur kayit yapiyorsun. Bugun ilk mood girisini yap."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationIdentifiers.morningReminder,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifiers.morningReminder])
        try await center.add(request)
    }

    func scheduleEvening(at components: DateComponents, moodCheckInsThisWeek: Int) async throws {
        let safeCheckIns = min(max(moodCheckInsThisWeek, 0), 7)
        let content = UNMutableNotificationContent()
        content.title = "Aksam mood kontrolu"
        content.body = "Bu hafta \(safeCheckIns)/7 gun kayit tamamlandi. Aksam mood'unu eklemeyi unutma."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationIdentifiers.eveningReminder,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifiers.eveningReminder])
        try await center.add(request)
    }

    func scheduleWeekly(at components: DateComponents, trackedDays: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Haftalik rapor hazirligi"
        content.body = "Son \(max(trackedDays, 0)) gunde veri topladin. Haftalik raporun icin son mood girisini yap."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationIdentifiers.weeklyReminder,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifiers.weeklyReminder])
        try await center.add(request)
    }

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }
}

private enum NotificationIdentifiers {
    static let morningReminder = "morningMoodReminder"
    static let eveningReminder = "eveningMoodReminder"
    static let weeklyReminder = "weeklyInsightReminder"
}

#else
final class UserNotificationService: NotificationServiceProtocol {
    func requestPermission() async throws -> Bool { true }

    func scheduleMorning(at components: DateComponents, streakDays: Int) async throws {
        _ = components
        _ = streakDays
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
