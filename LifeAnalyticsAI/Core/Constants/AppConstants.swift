// MARK: - Core.Constants

import Foundation

enum AppConstants {
    enum API {
        static let llmBaseURL = "https://life-analytics-proxy.hsynhbk.workers.dev/v1/insight"
        static let healthCheckURL = "https://life-analytics-proxy.hsynhbk.workers.dev/health"
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
        static let patternWindowDays = 30
        static let sleepBucketBoundaryHour = 12
    }

    enum Insights {
        static let cardMaxLength = 160
        static let cardTruncatedLength = 157
        static let historyFetchLimit = 200
        static let recentFallbackLimit = 10
        static let predictionWindowDays = 30
    }

    enum Mood {
        static let scaleMin = 1
        static let scaleMax = 5
    }

    enum Notifications {
        enum Channel: String {
            case morning
            case evening
            case weekly

            init?(categoryIdentifier: String) {
                switch categoryIdentifier {
                case Category.morning:
                    self = .morning
                case Category.evening:
                    self = .evening
                case Category.weekly:
                    self = .weekly
                default:
                    return nil
                }
            }
        }

        static let morningHour = 7
        static let morningMinute = 30
        static let eveningHour = 21
        static let eveningMinute = 0
        static let weeklyReportDay = 1 // Pazar
        static let weeklyReportHour = 19
        static let weeklyReportMinute = 0

        enum RequestID {
            static let morningReminder = "morningMoodReminder"
            static let eveningReminder = "eveningMoodReminder"
            static let weeklyReminder = "weeklyInsightReminder"
        }

        enum Category {
            static let morning = "morningMoodCategory"
            static let evening = "eveningMoodCategory"
            static let weekly = "weeklyReportCategory"
        }

        enum Action {
            static let openMoodEntry = "openMoodEntryAction"
            static let openReport = "openReportAction"
        }

        enum DeepLink {
            static let moodEntry = "lifeanalytics://mood-entry"
            static let report = "lifeanalytics://report"
        }
    }

    enum Storage {
        static let userDefaultsSuite = "com.lifeanalytics.defaults"
    }

    enum Subscription {
        static let groupID = "premium_group"
        static let monthlyID = "com.lifeanalytics.premium.monthly"
        static let yearlyID = "com.lifeanalytics.premium.yearly"
        static let allProductIDs: Set<String> = [monthlyID, yearlyID]
        static let freeInsightsPerDay = 1
        static let freeInsightHistoryLimit = 3
        static let freeChartDaysLimit = 7
    }

    enum URLs {
        static let terms = URL(string: "https://lifeanalytics.app/terms")
        static let privacy = URL(string: "https://lifeanalytics.app/privacy")
    }

    enum UI {
        static let primaryColor = "PrimaryBlue"
        static let animationDuration = 0.3
    }

    enum Widget {
        static let quickMoodRefreshHours = 2
        static let quickMoodButtonMinHeight = 32
    }
}
