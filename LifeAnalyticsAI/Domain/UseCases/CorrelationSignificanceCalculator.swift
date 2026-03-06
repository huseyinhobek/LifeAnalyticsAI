// MARK: - Domain.UseCases

import Foundation

struct CorrelationSignificanceResult: Codable, Hashable {
    let pValue: Double
    let isSignificant: Bool
}

protocol CorrelationSignificanceCalculatorProtocol {
    func execute(
        correlation: Double,
        sampleSize: Int,
        alpha: Double
    ) async -> CorrelationSignificanceResult?
}

final class CorrelationSignificanceCalculator: CorrelationSignificanceCalculatorProtocol {
    func execute(
        correlation: Double,
        sampleSize: Int,
        alpha: Double = AppConstants.Health.pValueThreshold
    ) async -> CorrelationSignificanceResult? {
        guard sampleSize >= 4 else { return nil }

        let boundedCorrelation = min(0.999_999, max(-0.999_999, correlation))
        let fisherZ = 0.5 * log((1 + boundedCorrelation) / (1 - boundedCorrelation))
        let testStatistic = abs(fisherZ) * sqrt(Double(sampleSize - 3))

        let pValue = twoTailedPValueFromNormal(z: testStatistic)
        return CorrelationSignificanceResult(
            pValue: pValue,
            isSignificant: pValue < alpha
        )
    }

    private func twoTailedPValueFromNormal(z: Double) -> Double {
        let cdf = 0.5 * erfc(-z / sqrt(2))
        let tail = 1 - cdf
        return max(0, min(1, 2 * tail))
    }
}
