// MARK: - Core.Constants

import Foundation

enum AppConstants {
    enum API {
        static let llmBaseURL = "https://api.anthropic.com/v1/messages"
        static let llmModel = "claude-sonnet-4-5-20250929"
        static let maxTokens = 1000
        static let llmDailyTokenLimit = 30_000
        static let llmMonthlyTokenLimit = 500_000
        static let llmCacheTTLSeconds: TimeInterval = 60 * 60 * 6
    }

    enum Health {
        static let minDataDaysForInsight = 14
        static let correlationThreshold = 0.3
        static let pValueThreshold = 0.05
        static let anomalyZScoreThreshold = 1.5
    }

    enum Mood {
        static let scaleMin = 1
        static let scaleMax = 5
    }

    enum Notifications {
        static let morningHour = 7
        static let morningMinute = 30
        static let eveningHour = 21
        static let eveningMinute = 0
        static let weeklyReportDay = 1 // Pazar
    }

    enum Storage {
        static let keychainService = "com.lifeanalytics.keychain"
        static let userDefaultsSuite = "com.lifeanalytics.defaults"
    }

    enum UI {
        static let primaryColor = "PrimaryBlue"
        static let animationDuration = 0.3
    }
}
