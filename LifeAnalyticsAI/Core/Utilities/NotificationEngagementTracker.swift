// MARK: - Core.Utilities

import Foundation

enum NotificationEngagementTracker {
    enum Channel: String {
        case morning
        case evening
        case weekly
    }

    private static let defaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite)!

    static func recordScheduled(for channel: Channel, scheduledAt: Date = Date()) {
        let scheduled = defaults.integer(forKey: scheduledKey(for: channel)) + 1
        defaults.set(scheduled, forKey: scheduledKey(for: channel))
        defaults.set(scheduledAt, forKey: lastScheduledAtKey(for: channel))

        logMetrics(for: channel, event: "scheduled")
    }

    static func recordOpened(categoryIdentifier: String, actionIdentifier: String, openedAt: Date = Date()) {
        guard let channel = channel(for: categoryIdentifier) else { return }

        let opened = defaults.integer(forKey: openedKey(for: channel)) + 1
        defaults.set(opened, forKey: openedKey(for: channel))
        defaults.set(openedAt, forKey: lastOpenedAtKey(for: channel))
        defaults.set(actionIdentifier, forKey: lastActionKey(for: channel))

        logMetrics(for: channel, event: "opened")
    }

    private static func logMetrics(for channel: Channel, event: String) {
        let scheduled = defaults.integer(forKey: scheduledKey(for: channel))
        let opened = defaults.integer(forKey: openedKey(for: channel))
        let openRate = scheduled > 0 ? Double(opened) / Double(scheduled) : 0
        let percent = Int((openRate * 100).rounded())

        AppLogger.notification.info(
            "Notification stats event=\(event) channel=\(channel.rawValue) scheduled=\(scheduled) opened=\(opened) openRatePercent=\(percent)"
        )
    }

    private static func channel(for categoryIdentifier: String) -> Channel? {
        switch categoryIdentifier {
        case AppConstants.Notifications.Category.morning:
            return .morning
        case AppConstants.Notifications.Category.evening:
            return .evening
        case AppConstants.Notifications.Category.weekly:
            return .weekly
        default:
            return nil
        }
    }

    private static func scheduledKey(for channel: Channel) -> String {
        "notificationEngagementScheduled_\(channel.rawValue)"
    }

    private static func openedKey(for channel: Channel) -> String {
        "notificationEngagementOpened_\(channel.rawValue)"
    }

    private static func lastScheduledAtKey(for channel: Channel) -> String {
        "notificationEngagementLastScheduledAt_\(channel.rawValue)"
    }

    private static func lastOpenedAtKey(for channel: Channel) -> String {
        "notificationEngagementLastOpenedAt_\(channel.rawValue)"
    }

    private static func lastActionKey(for channel: Channel) -> String {
        "notificationEngagementLastAction_\(channel.rawValue)"
    }
}
