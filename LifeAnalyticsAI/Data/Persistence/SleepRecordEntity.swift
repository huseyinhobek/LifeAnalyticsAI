// MARK: - Data.Persistence

import Foundation
import SwiftData

@Model
final class SleepRecordEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var bedtime: Date
    var wakeTime: Date
    var totalMinutes: Int
    var deepSleepMinutes: Int?
    var remSleepMinutes: Int?
    var efficiency: Double?
    var source: String
    var createdAt: Date

    init(
        id: UUID,
        date: Date,
        bedtime: Date,
        wakeTime: Date,
        totalMinutes: Int,
        deepSleepMinutes: Int?,
        remSleepMinutes: Int?,
        efficiency: Double?,
        source: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.totalMinutes = totalMinutes
        self.deepSleepMinutes = deepSleepMinutes
        self.remSleepMinutes = remSleepMinutes
        self.efficiency = efficiency
        self.source = source
        self.createdAt = createdAt
    }

    func toDomain() -> SleepRecord {
        SleepRecord(
            id: id,
            date: date,
            bedtime: bedtime,
            wakeTime: wakeTime,
            totalMinutes: totalMinutes,
            deepSleepMinutes: deepSleepMinutes,
            remSleepMinutes: remSleepMinutes,
            lightSleepMinutes: nil,
            efficiency: efficiency,
            source: SleepRecord.DataSource(rawValue: source) ?? .manual
        )
    }

    static func fromDomain(_ record: SleepRecord) -> SleepRecordEntity {
        SleepRecordEntity(
            id: record.id,
            date: record.date,
            bedtime: record.bedtime,
            wakeTime: record.wakeTime,
            totalMinutes: record.totalMinutes,
            deepSleepMinutes: record.deepSleepMinutes,
            remSleepMinutes: record.remSleepMinutes,
            efficiency: record.efficiency,
            source: record.source.rawValue,
            createdAt: Date()
        )
    }
}
