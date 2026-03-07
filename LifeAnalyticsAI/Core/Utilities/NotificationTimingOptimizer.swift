// MARK: - Core.Utilities

import Foundation

enum NotificationTimingOptimizer {
    enum Channel: String {
        case morning
        case evening
        case weekly
    }

    private static let defaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite)!

    static func recordOpen(categoryIdentifier: String, openedAt: Date = Date()) {
        guard let channel = channel(for: categoryIdentifier) else { return }
        let hour = Calendar.current.component(.hour, from: openedAt)
        var histogram = histogramForChannel(channel)
        histogram[hour, default: 0] += 1
        defaults.set(histogram, forKey: key(for: channel))
    }

    static func optimalHour(for channel: Channel, fallback: Int, allowedRange: ClosedRange<Int>) -> Int {
        let histogram = histogramForChannel(channel)
        let best = histogram
            .filter { allowedRange.contains($0.key) }
            .max { lhs, rhs in
                if lhs.value == rhs.value {
                    return abs(lhs.key - fallback) > abs(rhs.key - fallback)
                }
                return lhs.value < rhs.value
            }

        return best?.key ?? fallback
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

    private static func histogramForChannel(_ channel: Channel) -> [Int: Int] {
        let raw = defaults.dictionary(forKey: key(for: channel)) ?? [:]
        var parsed: [Int: Int] = [:]
        for (rawHour, rawCount) in raw {
            guard let hour = Int(rawHour) else { continue }
            if let count = rawCount as? Int {
                parsed[hour] = count
            } else if let count = rawCount as? NSNumber {
                parsed[hour] = count.intValue
            }
        }
        return parsed
    }

    private static func key(for channel: Channel) -> String {
        "notificationOpenHistogram_\(channel.rawValue)"
    }
}
