// MARK: - Domain.UseCases

import Accelerate
import Foundation

struct PearsonCorrelationResult: Codable, Hashable {
    let coefficient: Double
    let sampleSize: Int
}

protocol PearsonCorrelationCalculatorProtocol {
    func execute(
        lhs: [TimeSeriesDataPoint],
        rhs: [TimeSeriesDataPoint],
        minimumPoints: Int
    ) async -> PearsonCorrelationResult?
}

final class PearsonCorrelationCalculator: PearsonCorrelationCalculatorProtocol {
    func execute(
        lhs: [TimeSeriesDataPoint],
        rhs: [TimeSeriesDataPoint],
        minimumPoints: Int = AppConstants.Health.minDataDaysForInsight
    ) async -> PearsonCorrelationResult? {
        let aligned = alignByDate(lhs: lhs, rhs: rhs)
        guard aligned.x.count >= max(2, minimumPoints) else { return nil }

        let x = aligned.x
        let y = aligned.y

        let xMean = vDSP.mean(x)
        let yMean = vDSP.mean(y)

        let xCentered = x.map { $0 - xMean }
        let yCentered = y.map { $0 - yMean }

        let numerator = vDSP.dot(xCentered, yCentered)
        let xMagnitude = sqrt(vDSP.dot(xCentered, xCentered))
        let yMagnitude = sqrt(vDSP.dot(yCentered, yCentered))
        let denominator = xMagnitude * yMagnitude

        guard denominator > 0 else { return nil }
        let r = numerator / denominator

        return PearsonCorrelationResult(
            coefficient: min(1, max(-1, r)),
            sampleSize: x.count
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
}
