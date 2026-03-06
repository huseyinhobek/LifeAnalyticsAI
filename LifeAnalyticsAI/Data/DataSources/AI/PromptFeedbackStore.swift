// MARK: - Data.DataSources.AI

import Foundation

final class PromptFeedbackStore {
    private let defaults: UserDefaults
    private let keyPrefix = "prompt_feedback"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recordFeedback(type: Insight.InsightType, feedback: Insight.UserFeedback) {
        let helpfulKey = key(for: type, suffix: "helpful")
        let notHelpfulKey = key(for: type, suffix: "not_helpful")

        switch feedback {
        case .helpful:
            defaults.set(defaults.integer(forKey: helpfulKey) + 1, forKey: helpfulKey)
        case .notHelpful:
            defaults.set(defaults.integer(forKey: notHelpfulKey) + 1, forKey: notHelpfulKey)
        }
    }

    func optimizationHint(for type: Insight.InsightType?) -> String {
        let stats = feedbackStats(for: type)
        guard stats.total >= 3 else {
            return "Use balanced detail, keep output concise, and include one practical action."
        }

        let helpfulRate = Double(stats.helpful) / Double(stats.total)
        if helpfulRate < 0.4 {
            return "Recent feedback is mostly negative. Prefer shorter, more direct, and specific suggestions."
        }
        if helpfulRate > 0.7 {
            return "Recent feedback is mostly positive. Keep concise rationale and one concrete next step."
        }
        return "Keep a neutral tone with one clear, practical recommendation."
    }

    private func feedbackStats(for type: Insight.InsightType?) -> (helpful: Int, notHelpful: Int, total: Int) {
        let allTypes: [Insight.InsightType]
        if let type {
            allTypes = [type]
        } else {
            allTypes = [.correlation, .anomaly, .prediction, .trend, .seasonal]
        }

        let helpful = allTypes.reduce(0) { partial, type in
            partial + defaults.integer(forKey: key(for: type, suffix: "helpful"))
        }

        let notHelpful = allTypes.reduce(0) { partial, type in
            partial + defaults.integer(forKey: key(for: type, suffix: "not_helpful"))
        }

        return (helpful: helpful, notHelpful: notHelpful, total: helpful + notHelpful)
    }

    private func key(for type: Insight.InsightType, suffix: String) -> String {
        "\(keyPrefix).\(type.rawValue).\(suffix)"
    }
}
