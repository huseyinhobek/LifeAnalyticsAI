// MARK: - Presentation.Charts.Models

import Foundation
import SwiftUI

struct TimeSeriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let isEstimated: Bool

    var comparisonToAverage: Double?
    var annotation: String?

    init(
        date: Date,
        value: Double,
        isEstimated: Bool,
        comparisonToAverage: Double? = nil,
        annotation: String? = nil
    ) {
        self.date = date
        self.value = value
        self.isEstimated = isEstimated
        self.comparisonToAverage = comparisonToAverage
        self.annotation = annotation
    }
}

struct ComparisonDataSet {
    let current: [TimeSeriesPoint]
    let previous: [TimeSeriesPoint]
    let changePercentage: Double
}

struct CorrelationPoint: Identifiable {
    let id = UUID()
    let xValue: Double
    let yValue: Double
    let date: Date
    let xLabel: String
    let yLabel: String
}

struct CorrelationResult {
    let points: [CorrelationPoint]
    let rValue: Double
    let pValue: Double
    let sampleSize: Int
    let regressionSlope: Double
    let regressionIntercept: Double
    let confidence: ChartStyleGuide.ConfidenceLevel

    var regressionLine: [(x: Double, y: Double)] {
        guard let minX = points.map(\.xValue).min(),
              let maxX = points.map(\.xValue).max() else {
            return []
        }

        return [
            (x: minX, y: regressionSlope * minX + regressionIntercept),
            (x: maxX, y: regressionSlope * maxX + regressionIntercept)
        ]
    }
}

struct GaugeData {
    let value: Double
    let label: String
    let segments: [(range: ClosedRange<Double>, color: Color, label: String)]
}

extension Array where Element == TimeSeriesPoint {
    func downsampled(interval: Int) -> [TimeSeriesPoint] {
        guard interval > 1 else { return self }

        var result: [TimeSeriesPoint] = []
        for i in stride(from: 0, to: count, by: interval) {
            let chunk = Array(self[i..<Swift.min(i + interval, count)])
            let avgValue = chunk.map(\.value).reduce(0, +) / Double(chunk.count)
            let hasEstimated = chunk.contains(where: { $0.isEstimated })
            result.append(
                TimeSeriesPoint(
                    date: chunk[chunk.count / 2].date,
                    value: avgValue,
                    isEstimated: hasEstimated
                )
            )
        }

        return result
    }
}
