// MARK: - Presentation.Charts

import Charts
import SwiftUI

enum ChartStyleGuide {
    enum SemanticColor {
        static let sleep = Color(hex: "7B9BFF")
        static let mood = Color(hex: "5EDBA5")
        static let meetings = Color(hex: "FFB547")
        static let steps = Color(hex: "FF9B6A")
        static let heartRate = Color(hex: "FF7B7B")
        static let screenTime = Color(hex: "B79CFF")

        static let positive = Color(hex: "5EDBA5")
        static let negative = Color(hex: "FF7B7B")
        static let neutral = Color(hex: "8B95B0")

        static let confidenceHigh = Color(hex: "5EDBA5")
        static let confidenceMedium = Color(hex: "FFB547")
        static let confidenceLow = Color(hex: "FF7B7B")

        static let currentPeriod = Color(hex: "7B9BFF")
        static let previousPeriod = Color(hex: "7B9BFF").opacity(0.3)
        static let missingData = Color(hex: "2A2D38")
    }

    enum Gradient {
        static func areaFill(for color: Color) -> LinearGradient {
            LinearGradient(
                colors: [color.opacity(0.25), color.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static func barFill(for color: Color) -> LinearGradient {
            LinearGradient(
                colors: [color, color.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    enum Typography {
        static let chartTitle = Font.system(size: 15, weight: .bold)
        static let insightText = Font.system(size: 13, weight: .medium)
        static let axisLabel = Font.system(size: 10, weight: .medium)
        static let tooltipValue = Font.system(size: 14, weight: .bold, design: .rounded)
        static let tooltipLabel = Font.system(size: 10, weight: .medium)
        static let annotationText = Font.system(size: 10, weight: .semibold)
        static let confidenceLabel = Font.system(size: 9, weight: .semibold)
        static let emptyStateTitle = Font.system(size: 16, weight: .semibold)
        static let emptyStateBody = Font.system(size: 13)
    }

    enum Grid {
        static let lineColor = Color.white.opacity(0.04)
        static let axisColor = Color.white.opacity(0.08)
        static let lineWidth: CGFloat = 0.5
    }

    enum Sizing {
        static let chartHeight: CGFloat = 200
        static let miniChartHeight: CGFloat = 48
        static let sparklineHeight: CGFloat = 32
        static let barCornerRadius: CGFloat = 4
        static let lineWidth: CGFloat = 2.5
        static let pointSize: CGFloat = 6
        static let selectedPointSize: CGFloat = 10
        static let annotationLineWidth: CGFloat = 1
        static let chartPadding: CGFloat = 16
    }

    enum Animation {
        static let chartAppear: SwiftUI.Animation = .spring(response: 0.6, dampingFraction: 0.8)
        static let tooltipAppear: SwiftUI.Animation = .spring(response: 0.3)
        static let periodSwitch: SwiftUI.Animation = .easeInOut(duration: 0.3)
    }

    enum TimePeriod: String, CaseIterable, Identifiable {
        case week7 = "7g"
        case month30 = "30g"
        case quarter90 = "90g"
        case year365 = "1y"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .week7: return "7 " + "period.days_short".localized
            case .month30: return "30 " + "period.days_short".localized
            case .quarter90: return "90 " + "period.days_short".localized
            case .year365: return "1 " + "period.year_short".localized
            }
        }

        var days: Int {
            switch self {
            case .week7: return 7
            case .month30: return 30
            case .quarter90: return 90
            case .year365: return 365
            }
        }

        var downsampleInterval: Int {
            switch self {
            case .week7: return 1
            case .month30: return 1
            case .quarter90: return 3
            case .year365: return 7
            }
        }
    }

    enum ConfidenceLevel: String {
        case low, medium, high

        var color: Color {
            switch self {
            case .low: return SemanticColor.confidenceLow
            case .medium: return SemanticColor.confidenceMedium
            case .high: return SemanticColor.confidenceHigh
            }
        }

        var label: String {
            switch self {
            case .low: return "insights.confidence.low".localized
            case .medium: return "insights.confidence.medium".localized
            case .high: return "insights.confidence.high".localized
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = (int >> 16) & 0xFF
        let g = (int >> 8) & 0xFF
        let b = int & 0xFF

        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
