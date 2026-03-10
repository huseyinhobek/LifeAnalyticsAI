// MARK: - Core.Utilities

import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.lifeanalytics.app"

    static let health = Logger(subsystem: subsystem, category: "HealthKit")
    static let calendar = Logger(subsystem: subsystem, category: "Calendar")
    static let mood = Logger(subsystem: subsystem, category: "Mood")
    static let insight = Logger(subsystem: subsystem, category: "InsightEngine")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let notification = Logger(subsystem: subsystem, category: "Notification")
}
