// MARK: - Presentation.Charts.Components

import Charts
import SwiftUI

struct ComparisonBarChart: View {
    let title: String
    let insight: String?
    let data: [BarDataPoint]
    let color: Color
    let unit: String

    struct BarDataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let isHighlighted: Bool
        let comparisonValue: Double?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(ChartStyleGuide.Typography.chartTitle)
                .foregroundStyle(Color(hex: "F2F4F8"))

            if let insight {
                Text(insight)
                    .font(ChartStyleGuide.Typography.insightText)
                    .foregroundStyle(Color(hex: "A0A8BE"))
            }

            Chart(data) { point in
                BarMark(
                    x: .value("Label", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    point.isHighlighted
                        ? ChartStyleGuide.Gradient.barFill(for: color)
                        : ChartStyleGuide.Gradient.barFill(for: color.opacity(0.4))
                )
                .cornerRadius(ChartStyleGuide.Sizing.barCornerRadius)

                PointMark(
                    x: .value("Label", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(point.isHighlighted ? color : color.opacity(0.45))
                .symbolSize(point.isHighlighted ? 36 : 24)

                if let comp = point.comparisonValue {
                    RuleMark(y: .value("Previous", comp))
                        .foregroundStyle(ChartStyleGuide.SemanticColor.previousPeriod)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
            }
            .frame(height: ChartStyleGuide.Sizing.chartHeight)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(ChartStyleGuide.Typography.axisLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: ChartStyleGuide.Grid.lineWidth))
                        .foregroundStyle(ChartStyleGuide.Grid.lineColor)
                    AxisValueLabel()
                        .font(ChartStyleGuide.Typography.axisLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }

            if let max = data.map(\.value).max() {
                Text("Max: \(String(format: "%.1f", max)) \(unit)")
                    .font(ChartStyleGuide.Typography.tooltipLabel)
                    .foregroundStyle(Color(hex: "5C6380"))
            }
        }
        .padding(ChartStyleGuide.Sizing.chartPadding)
        .background(
            LinearGradient(
                colors: [Color(hex: "11131B"), Color(hex: "171B2A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 120, height: 120)
                .blur(radius: 28)
                .offset(x: 30, y: -42)
        }
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.04), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        guard let last = data.last else { return "chart.no_data".localized }
        return String(format: "chart.accessibility_summary".localized, String(format: "%.1f", last.value), unit)
    }
}
