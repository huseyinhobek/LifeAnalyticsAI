// MARK: - Core.Utilities

import Foundation
import Observation

@Observable
final class UserDefaultsManager {
    private let defaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite)!

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

    enum InsightTone: String {
        case concise
        case detailed
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
}
