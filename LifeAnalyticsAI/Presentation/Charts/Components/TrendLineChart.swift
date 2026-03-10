// MARK: - Presentation.Charts.Components

import Charts
import SwiftUI

struct TrendLineChart: View {
    let title: String
    let insight: String?
    let data: [TimeSeriesPoint]
    let color: Color
    let unit: String
    let comparison: ComparisonDataSet?
    let annotations: [TimeSeriesPoint]
    let period: ChartStyleGuide.TimePeriod

    @State private var selectedPoint: TimeSeriesPoint?
    @State private var showComparison = false

    init(
        title: String,
        insight: String? = nil,
        data: [TimeSeriesPoint],
        color: Color,
        unit: String,
        comparison: ComparisonDataSet? = nil,
        annotations: [TimeSeriesPoint] = [],
        period: ChartStyleGuide.TimePeriod = .week7
    ) {
        self.title = title
        self.insight = insight
        self.data = data
        self.color = color
        self.unit = unit
        self.comparison = comparison
        self.annotations = annotations
        self.period = period
    }

    private var processedData: [TimeSeriesPoint] {
        data.downsampled(interval: period.downsampleInterval)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            chartHeader

            if let insight {
                Text(insight)
                    .font(ChartStyleGuide.Typography.insightText)
                    .foregroundStyle(Color(hex: "A0A8BE"))
                    .lineLimit(2)
            }

            if let selected = selectedPoint {
                tooltipView(for: selected)
            }

            Chart {
                if showComparison, let prev = comparison?.previous {
                    ForEach(prev) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(ChartStyleGuide.SemanticColor.previousPeriod)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }
                }

                ForEach(processedData) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(ChartStyleGuide.Gradient.areaFill(for: color))
                    .interpolationMethod(.catmullRom)
                }

                ForEach(processedData) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Value", point.value),
                        yEnd: .value("Glow", point.value + 0.05)
                    )
                    .foregroundStyle(color.opacity(0.12))
                    .interpolationMethod(.catmullRom)
                }

                ForEach(processedData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(point.isEstimated ? color.opacity(0.4) : color)
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: ChartStyleGuide.Sizing.lineWidth,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: point.isEstimated ? [4, 3] : []
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                if let selected = selectedPoint {
                    PointMark(
                        x: .value("Date", selected.date),
                        y: .value("Value", selected.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(ChartStyleGuide.Sizing.selectedPointSize * ChartStyleGuide.Sizing.selectedPointSize)

                    RuleMark(x: .value("Date", selected.date))
                        .foregroundStyle(color.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }

                ForEach(annotations) { ann in
                    PointMark(
                        x: .value("Date", ann.date),
                        y: .value("Value", ann.value)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(30)
                    .annotation(position: .top, spacing: 4) {
                        if let text = ann.annotation {
                            Text(text)
                                .font(ChartStyleGuide.Typography.annotationText)
                                .foregroundStyle(ChartStyleGuide.SemanticColor.negative)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(hex: "1E2540"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .frame(height: ChartStyleGuide.Sizing.chartHeight)
            .chartXAxis {
                AxisMarks(values: .stride(by: period == .week7 ? .day : .weekOfYear, count: 1)) { _ in
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
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let x = drag.location.x - geo[plotFrame].origin.x
                                    guard let date: Date = proxy.value(atX: x) else { return }
                                    if let closest = processedData.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    }) {
                                        withAnimation(ChartStyleGuide.Animation.tooltipAppear) {
                                            selectedPoint = closest
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation { selectedPoint = nil }
                                }
                        )
                }
            }
            .animation(ChartStyleGuide.Animation.chartAppear, value: processedData.count)

            if comparison != nil {
                compareToggle
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
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 140, height: 140)
                .blur(radius: 30)
                .offset(x: -28, y: -48)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilitySummary)
    }

    private var chartHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ChartStyleGuide.Typography.chartTitle)
                    .foregroundStyle(Color(hex: "F2F4F8"))

                if let last = processedData.last {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", last.value))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(color)
                        Text(unit)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "8B95B0"))
                    }
                }
            }

            Spacer()

            if processedData.count >= 2 {
                let first = processedData.first!.value
                let last = processedData.last!.value
                let change = first > 0 ? ((last - first) / first) * 100 : 0

                HStack(spacing: 3) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(String(format: "%.0f%%", abs(change)))
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(change >= 0 ? ChartStyleGuide.SemanticColor.positive : ChartStyleGuide.SemanticColor.negative)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((change >= 0 ? ChartStyleGuide.SemanticColor.positive : ChartStyleGuide.SemanticColor.negative).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func tooltipView(for point: TimeSeriesPoint) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(point.date, style: .date)
                    .font(ChartStyleGuide.Typography.tooltipLabel)
                    .foregroundStyle(Color(hex: "8B95B0"))
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(format: "%.1f", point.value))
                        .font(ChartStyleGuide.Typography.tooltipValue)
                        .foregroundStyle(color)
                    Text(unit)
                        .font(ChartStyleGuide.Typography.tooltipLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }

            if let comp = point.comparisonToAverage {
                Divider().frame(height: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("chart.vs_average".localized)
                        .font(ChartStyleGuide.Typography.tooltipLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                    Text(String(format: "%+.0f%%", comp))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(comp >= 0 ? ChartStyleGuide.SemanticColor.positive : ChartStyleGuide.SemanticColor.negative)
                }
            }
        }
        .padding(10)
        .background(Color(hex: "1E2540"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var compareToggle: some View {
        Button {
            withAnimation(ChartStyleGuide.Animation.periodSwitch) {
                showComparison.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .stroke(showComparison ? color : Color(hex: "5C6380"), lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                    .overlay {
                        if showComparison {
                            Circle().fill(color).frame(width: 8, height: 8)
                        }
                    }
                Text("chart.compare_previous".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "8B95B0"))
            }
        }
    }

    private var accessibilitySummary: String {
        guard let last = processedData.last else { return "chart.no_data".localized }
        return String(format: "chart.accessibility_summary".localized, String(format: "%.1f", last.value), unit)
    }
}
