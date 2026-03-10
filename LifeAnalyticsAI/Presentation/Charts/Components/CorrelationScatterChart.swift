// MARK: - Presentation.Charts.Components

import Charts
import SwiftUI

struct CorrelationScatterChart: View {
    let title: String
    let insight: String?
    let result: CorrelationResult
    let xLabel: String
    let yLabel: String
    let xColor: Color
    let yColor: Color

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

            confidenceBadge

            Chart {
                ForEach(result.points) { point in
                    PointMark(
                        x: .value(xLabel, point.xValue),
                        y: .value(yLabel, point.yValue)
                    )
                    .foregroundStyle(xColor.opacity(0.7))
                    .symbolSize(40)
                }

                if result.regressionLine.count == 2 {
                    let line = result.regressionLine
                    LineMark(
                        x: .value(xLabel, line[0].x),
                        y: .value(yLabel, line[0].y)
                    )
                    .foregroundStyle(yColor.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))

                    LineMark(
                        x: .value(xLabel, line[1].x),
                        y: .value(yLabel, line[1].y)
                    )
                    .foregroundStyle(yColor.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }
            .frame(height: ChartStyleGuide.Sizing.chartHeight)
            .chartXAxisLabel(position: .bottom, alignment: .center) {
                Text(xLabel)
                    .font(ChartStyleGuide.Typography.axisLabel)
                    .foregroundStyle(Color(hex: "5C6380"))
            }
            .chartYAxisLabel(position: .leading, alignment: .center) {
                Text(yLabel)
                    .font(ChartStyleGuide.Typography.axisLabel)
                    .foregroundStyle(Color(hex: "5C6380"))
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: ChartStyleGuide.Grid.lineWidth))
                        .foregroundStyle(ChartStyleGuide.Grid.lineColor)
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

            statisticsFooter
        }
        .padding(ChartStyleGuide.Sizing.chartPadding)
        .background(Color(hex: "12141A"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.04), lineWidth: 1))
    }

    private var confidenceBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(result.confidence.color)
                .frame(width: 6, height: 6)
            Text("chart.confidence".localized + ": " + result.confidence.label)
                .font(ChartStyleGuide.Typography.confidenceLabel)
                .foregroundStyle(result.confidence.color)

            Text("·")
                .foregroundStyle(Color(hex: "5C6380"))

            Text("n=\(result.sampleSize)")
                .font(ChartStyleGuide.Typography.confidenceLabel)
                .foregroundStyle(Color(hex: "5C6380"))
        }
    }

    private var statisticsFooter: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 1) {
                Text("r")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(hex: "5C6380"))
                Text(String(format: "%.2f", result.rValue))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "A0A8BE"))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("p")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(hex: "5C6380"))
                Text(result.pValue < 0.001 ? "<0.001" : String(format: "%.3f", result.pValue))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(result.pValue < 0.05 ? ChartStyleGuide.SemanticColor.positive : Color(hex: "A0A8BE"))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("chart.sample_size".localized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "5C6380"))
                Text("\(result.sampleSize) " + "chart.days".localized)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "A0A8BE"))
            }
        }
        .padding(.top, 4)
    }
}
