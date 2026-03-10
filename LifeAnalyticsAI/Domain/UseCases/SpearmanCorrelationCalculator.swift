// MARK: - Domain.UseCases

import Accelerate
import Foundation

struct SpearmanCorrelationResult: Codable, Hashable {
    let coefficient: Double
    let sampleSize: Int
}

protocol SpearmanCorrelationCalculatorProtocol {
    func execute(
        lhs: [TimeSeriesDataPoint],
        rhs: [TimeSeriesDataPoint],
        minimumPoints: Int
    ) async -> SpearmanCorrelationResult?
}

final class SpearmanCorrelationCalculator: SpearmanCorrelationCalculatorProtocol {
    func execute(
        lhs: [TimeSeriesDataPoint],
        rhs: [TimeSeriesDataPoint],
        minimumPoints: Int = AppConstants.Health.minDataDaysForInsight
    ) async -> SpearmanCorrelationResult? {
        let aligned = alignByDate(lhs: lhs, rhs: rhs)
        guard aligned.x.count >= max(2, minimumPoints) else { return nil }

        let xRanks = rank(aligned.x)
        let yRanks = rank(aligned.y)

        let xMean = vDSP.mean(xRanks)
        let yMean = vDSP.mean(yRanks)
        let xCentered = xRanks.map { $0 - xMean }
        let yCentered = yRanks.map { $0 - yMean }

        let numerator = vDSP.dot(xCentered, yCentered)
        let xMagnitude = sqrt(vDSP.dot(xCentered, xCentered))
        let yMagnitude = sqrt(vDSP.dot(yCentered, yCentered))
        let denominator = xMagnitude * yMagnitude

        guard denominator > 0 else { return nil }
        let r = numerator / denominator

        return SpearmanCorrelationResult(
            coefficient: min(1, max(-1, r)),
            sampleSize: aligned.x.count
        )
    }

    private func alignByDate(
        lhs: [TimeSeriesDataPoint],
        rhs: [TimeSeriesDataPoint]
    ) -> (x: [Double], y: [Double]) {
        let lhsDaily = aggregateDailyAverage(lhs)
        let rhsDaily = aggregateDailyAverage(rhs)

        let dates = Set(lhsDaily.keys).intersection(rhsDaily.keys).sorted()
        var x: [Double] = []
        var y: [Double] = []
        x.reserveCapacity(dates.count)
        y.reserveCapacity(dates.count)

        for date in dates {
            guard let xv = lhsDaily[date], let yv = rhsDaily[date] else { continue }
            x.append(xv)
            y.append(yv)
        }

        return (x, y)
    }

    private func aggregateDailyAverage(_ points: [TimeSeriesDataPoint]) -> [Date: Double] {
        let grouped = Dictionary(grouping: points, by: { $0.date.startOfDay })
        return grouped.reduce(into: [Date: Double]()) { result, item in
            let values = item.value.map(\.normalizedValue)
            guard !values.isEmpty else { return }
            result[item.key] = vDSP.mean(values)
        }
    }

    private func rank(_ values: [Double]) -> [Double] {
        let indexed = values.enumerated().map { (offset: $0.offset, value: $0.element) }
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.offset < rhs.offset }
                return lhs.value < rhs.value
            }

        var ranks = Array(repeating: 0.0, count: values.count)
        var index = 0

        while index < indexed.count {
            let start = index
            let value = indexed[index].value
            while index < indexed.count && indexed[index].value == value {
                index += 1
            }

            let end = index
            let averageRank = (Double(start + 1) + Double(end)) / 2.0
            for position in start..<end {
                ranks[indexed[position].offset] = averageRank
            }
        }

        return ranks
    }
}
