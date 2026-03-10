// MARK: - Presentation.Charts.Components

import Charts
import SwiftUI

struct SparklineView: View {
    let data: [Double]
    let color: Color
    let height: CGFloat

    init(data: [Double], color: Color, height: CGFloat = ChartStyleGuide.Sizing.sparklineHeight) {
        self.data = data
        self.color = color
        self.height = height
    }

    var body: some View {
        Chart(Array(data.enumerated()), id: \.offset) { index, value in
            AreaMark(
                x: .value("Index", index),
                y: .value("Value", value)
            )
            .foregroundStyle(ChartStyleGuide.Gradient.areaFill(for: color))
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Index", index),
                y: .value("Value", value)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
    }
}
