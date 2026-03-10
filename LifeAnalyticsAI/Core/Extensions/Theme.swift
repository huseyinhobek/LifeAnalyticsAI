// MARK: - Core.Extensions

import SwiftUI

enum Theme {
    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.title3, design: .default).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .default)

    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let cornerRadius: CGFloat = 12

    static func moodColor(_ value: Int) -> Color {
        switch value {
        case 5:
            return Color("MoodExcellent")
        case 4:
            return Color("MoodGood")
        case 3:
            return Color("MoodNeutral")
        case 2:
            return Color("MoodLow")
        default:
            return Color("MoodBad")
        }
    }
}
