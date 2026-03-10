// MARK: - Core.Utilities

import Foundation

enum NotificationEngagementTracker {
    private static let defaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite) else {
            AppLogger.notification.warning("Shared UserDefaults suite unavailable for engagement tracking, using standard")
            return .standard
        }
        return defaults
    }()

    static func recordScheduled(for channel: AppConstants.Notifications.Channel, scheduledAt: Date = Date()) {
        let scheduled = defaults.integer(forKey: scheduledKey(for: channel)) + 1
        defaults.set(scheduled, forKey: scheduledKey(for: channel))
        defaults.set(scheduledAt, forKey: lastScheduledAtKey(for: channel))

        logMetrics(for: channel, event: "scheduled")
    }

    static func recordOpened(categoryIdentifier: String, actionIdentifier: String, openedAt: Date = Date()) {
        guard let channel = AppConstants.Notifications.Channel(categoryIdentifier: categoryIdentifier) else { return }

        let opened = defaults.integer(forKey: openedKey(for: channel)) + 1
        defaults.set(opened, forKey: openedKey(for: channel))
        defaults.set(openedAt, forKey: lastOpenedAtKey(for: channel))
        defaults.set(actionIdentifier, forKey: lastActionKey(for: channel))

        logMetrics(for: channel, event: "opened")
    }

    private static func logMetrics(for channel: AppConstants.Notifications.Channel, event: String) {
        let scheduled = defaults.integer(forKey: scheduledKey(for: channel))
        let opened = defaults.integer(forKey: openedKey(for: channel))
        let openRate = scheduled > 0 ? Double(opened) / Double(scheduled) : 0
        let percent = Int((openRate * 100).rounded())

        AppLogger.notification.info(
            "Notification stats event=\(event) channel=\(channel.rawValue) scheduled=\(scheduled) opened=\(opened) openRatePercent=\(percent)"
        )
    }

    private static func scheduledKey(for channel: AppConstants.Notifications.Channel) -> String {
        "notificationEngagementScheduled_\(channel.rawValue)"
    }

    private static func openedKey(for channel: AppConstants.Notifications.Channel) -> String {
        "notificationEngagementOpened_\(channel.rawValue)"
    }

    private static func lastScheduledAtKey(for channel: AppConstants.Notifications.Channel) -> String {
        "notificationEngagementLastScheduledAt_\(channel.rawValue)"
    }

    private static func lastOpenedAtKey(for channel: AppConstants.Notifications.Channel) -> String {
        "notificationEngagementLastOpenedAt_\(channel.rawValue)"
    }

    private static func lastActionKey(for channel: AppConstants.Notifications.Channel) -> String {
        "notificationEngagementLastAction_\(channel.rawValue)"
    }
}
