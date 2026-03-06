// MARK: - Domain.Models

import Foundation

struct Insight: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let type: InsightType
    let title: String
    let body: String
    let confidenceLevel: ConfidenceLevel
    let relatedMetrics: [MetricReference]
    var userFeedback: UserFeedback?

    enum InsightType: String, Codable {
        case correlation
        case anomaly
        case prediction
        case trend
        case seasonal
    }

    enum ConfidenceLevel: String, Codable {
        case low
        case medium
        case high

        var label: String {
            switch self {
            case .low:
                return "Dusuk"
            case .medium:
                return "Orta"
            case .high:
                return "Yuksek"
            }
        }
    }

    enum UserFeedback: String, Codable {
        case helpful
        case notHelpful
    }
}

struct MetricReference: Codable, Hashable {
    let name: String
    let value: Double
    let unit: String
    let trend: Trend

    enum Trend: String, Codable {
        case up
        case down
        case stable
    }
}

struct WeeklyReport: Identifiable, Codable, Hashable {
    let id: UUID
    let weekStartDate: Date
    let summary: String
    let insights: [Insight]
    let keyMetrics: [MetricReference]
    let prediction: String?
}
