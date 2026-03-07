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
            return "mood.very_bad".localized
        case .bad:
            return "mood.bad".localized
        case .neutral:
            return "mood.neutral".localized
        case .good:
            return "mood.good".localized
        case .veryGood:
            return "mood.very_good".localized
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
            return "activity.exercise".localized
        case .work:
            return "activity.work".localized
        case .social:
            return "activity.social".localized
        case .reading:
            return "activity.reading".localized
        case .meditation:
            return "activity.meditation".localized
        case .nature:
            return "activity.nature".localized
        case .family:
            return "activity.family".localized
        case .travel:
            return "activity.travel".localized
        }
    }
}
