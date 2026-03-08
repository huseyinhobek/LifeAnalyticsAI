// MARK: - Domain.Models

import Foundation

enum PremiumFeature: String, CaseIterable {
    case unlimitedInsights
    case weeklyReport
    case crossCorrelation
    case predictions
    case extendedTrends
    case fullInsightHistory
    case dataExport
    case priorityAI

    var displayName: String {
        "\(rawValue)_title".localized
    }

    var description: String {
        "\(rawValue)_desc".localized
    }
}
