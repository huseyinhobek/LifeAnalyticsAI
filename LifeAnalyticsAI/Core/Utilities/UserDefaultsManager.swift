// MARK: - Core.Utilities

import Foundation
import Observation

@Observable
final class UserDefaultsManager {
    private let defaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite) else {
            AppLogger.notification.warning("Shared UserDefaults suite unavailable, falling back to standard")
            return .standard
        }
        return defaults
    }()

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    var dataCollectionStartDate: Date? {
        get { defaults.object(forKey: Keys.dataCollectionStartDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.dataCollectionStartDate) }
    }

    var preferredInsightTone: InsightTone {
        get {
            guard let rawValue = defaults.string(forKey: Keys.preferredInsightTone),
                  let tone = InsightTone(rawValue: rawValue) else {
                return .concise
            }
            return tone
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.preferredInsightTone) }
    }

    var notificationsEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.notificationsEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.notificationsEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    var morningNotificationTime: Date {
        get {
            (defaults.object(forKey: Keys.morningNotificationTime) as? Date)
                ?? defaultTime(hour: AppConstants.Notifications.morningHour, minute: AppConstants.Notifications.morningMinute)
        }
        set { defaults.set(newValue, forKey: Keys.morningNotificationTime) }
    }

    var eveningNotificationTime: Date {
        get {
            (defaults.object(forKey: Keys.eveningNotificationTime) as? Date)
                ?? defaultTime(hour: AppConstants.Notifications.eveningHour, minute: AppConstants.Notifications.eveningMinute)
        }
        set { defaults.set(newValue, forKey: Keys.eveningNotificationTime) }
    }

    var weeklyReportEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.weeklyReportEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.weeklyReportEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.weeklyReportEnabled) }
    }

    var preferredTheme: AppTheme {
        get {
            guard let rawValue = defaults.string(forKey: Keys.preferredTheme),
                  let theme = AppTheme(rawValue: rawValue) else {
                return .system
            }
            return theme
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.preferredTheme) }
    }

    var healthKitSyncEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.healthKitSyncEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.healthKitSyncEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.healthKitSyncEnabled) }
    }

    var calendarSyncEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.calendarSyncEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.calendarSyncEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.calendarSyncEnabled) }
    }

    var appLockEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.appLockEnabled) == nil {
                return false
            }
            return defaults.bool(forKey: Keys.appLockEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.appLockEnabled) }
    }

    enum InsightTone: String {
        case concise
        case detailed
    }

    enum AppTheme: String, CaseIterable {
        case system
        case light
        case dark

        var title: String {
            switch self {
            case .system:
                return "theme.system".localized
            case .light:
                return "theme.light".localized
            case .dark:
                return "theme.dark".localized
            }
        }
    }

    private func defaultTime(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

private enum Keys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let dataCollectionStartDate = "dataCollectionStartDate"
    static let preferredInsightTone = "preferredInsightTone"
    static let notificationsEnabled = "notificationsEnabled"
    static let morningNotificationTime = "morningNotificationTime"
    static let eveningNotificationTime = "eveningNotificationTime"
    static let weeklyReportEnabled = "weeklyReportEnabled"
    static let preferredTheme = "preferredTheme"
    static let healthKitSyncEnabled = "healthKitSyncEnabled"
    static let calendarSyncEnabled = "calendarSyncEnabled"
    static let appLockEnabled = "appLockEnabled"
}
