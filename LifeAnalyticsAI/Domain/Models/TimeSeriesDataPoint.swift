// MARK: - Domain.Models

import Foundation

struct TimeSeriesDataPoint: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let source: Source
    let metric: Metric
    let rawValue: Double
    let normalizedValue: Double

    enum Source: String, Codable {
        case sleep
        case mood
        case calendar
    }

    enum Metric: String, Codable {
        case sleepHours
        case moodScore
        case meetingCount
        case meetingMinutes
    }
}
