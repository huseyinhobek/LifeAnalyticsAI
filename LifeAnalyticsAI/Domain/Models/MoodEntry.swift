// MARK: - Domain.Models

import Foundation

struct MoodEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let timestamp: Date
    let value: Int // 1-5
    let note: String?
    let activities: [ActivityTag]

    var moodLevel: MoodLevel {
        MoodLevel(rawValue: value) ?? .neutral
    }
}

enum MoodLevel: Int, Codable, CaseIterable {
    case veryBad = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case veryGood = 5

    var emoji: String {
        switch self {
        case .veryBad:
            return "😞"
        case .bad:
            return "😕"
        case .neutral:
            return "😐"
        case .good:
            return "🙂"
        case .veryGood:
            return "😄"
        }
    }

    var label: String {
        switch self {
        case .veryBad:
            return "Cok kotu"
        case .bad:
            return "Kotu"
        case .neutral:
            return "Notr"
        case .good:
            return "Iyi"
        case .veryGood:
            return "Cok iyi"
        }
    }
}

enum ActivityTag: String, Codable, CaseIterable {
    case exercise
    case work
    case social
    case reading
    case meditation
    case nature
    case family
    case travel

    var displayName: String {
        switch self {
        case .exercise:
            return "Egzersiz"
        case .work:
            return "Is"
        case .social:
            return "Sosyal"
        case .reading:
            return "Okuma"
        case .meditation:
            return "Meditasyon"
        case .nature:
            return "Doga"
        case .family:
            return "Aile"
        case .travel:
            return "Seyahat"
        }
    }
}
