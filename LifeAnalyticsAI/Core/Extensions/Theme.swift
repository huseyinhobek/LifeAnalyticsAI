// MARK: - Core.Extensions

import SwiftUI

enum Theme {
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 20, weight: .semibold)
    static let bodyFont = Font.system(size: 16, weight: .regular)
    static let captionFont = Font.system(size: 13, weight: .regular)

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
