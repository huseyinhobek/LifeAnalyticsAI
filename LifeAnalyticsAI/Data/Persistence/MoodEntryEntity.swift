// MARK: - Data.Persistence

import Foundation
import SwiftData

@Model
final class MoodEntryEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var timestamp: Date
    var value: Int
    var note: String?
    var activitiesJSON: String
    var createdAt: Date

    init(
        id: UUID,
        date: Date,
        timestamp: Date,
        value: Int,
        note: String?,
        activitiesJSON: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.timestamp = timestamp
        self.value = value
        self.note = note
        self.activitiesJSON = activitiesJSON
        self.createdAt = createdAt
    }

    func toDomain() -> MoodEntry {
        MoodEntry(
            id: id,
            date: date,
            timestamp: timestamp,
            value: value,
            note: note,
            activities: Self.decodeActivities(from: activitiesJSON)
        )
    }

    static func fromDomain(_ entry: MoodEntry) -> MoodEntryEntity {
        MoodEntryEntity(
            id: entry.id,
            date: entry.date,
            timestamp: entry.timestamp,
            value: entry.value,
            note: entry.note,
            activitiesJSON: encodeActivities(entry.activities),
            createdAt: Date()
        )
    }

    private static func encodeActivities(_ activities: [ActivityTag]) -> String {
        guard let data = try? JSONEncoder().encode(activities),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    private static func decodeActivities(from json: String) -> [ActivityTag] {
        guard let data = json.data(using: .utf8),
              let activities = try? JSONDecoder().decode([ActivityTag].self, from: data) else {
            return []
        }
        return activities
    }
}
