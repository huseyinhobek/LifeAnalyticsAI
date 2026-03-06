// MARK: - Core.Utilities

import Foundation
import OSLog

enum AppLogger {
    static let health = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HealthKit")
    static let calendar = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Calendar")
    static let mood = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Mood")
    static let insight = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "InsightEngine")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Network")
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI")
    static let notification = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Notification")
}
