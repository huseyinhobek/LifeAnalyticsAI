// MARK: - Domain.Models

import Foundation

struct SleepRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let bedtime: Date
    let wakeTime: Date
    let totalMinutes: Int
    let deepSleepMinutes: Int?
    let remSleepMinutes: Int?
    let lightSleepMinutes: Int?
    let efficiency: Double? // 0.0 - 1.0
    let source: DataSource

    var totalHours: Double { Double(totalMinutes) / 60.0 }
    var isAboveAverage: Bool? // computed after stats

    enum DataSource: String, Codable {
        case healthKit
        case manual
    }
}
