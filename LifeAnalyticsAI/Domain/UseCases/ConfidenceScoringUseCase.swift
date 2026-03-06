// MARK: - Domain.UseCases

import Foundation

struct CorrelationConfidenceScore: Identifiable, Codable, Hashable {
    let id: UUID
    let lhsMetric: TimeSeriesDataPoint.Metric
    let rhsMetric: TimeSeriesDataPoint.Metric
    let confidence: Insight.ConfidenceLevel
    let effectSize: Double
    let sampleSize: Int
}

protocol ConfidenceScoringUseCaseProtocol {
    func execute(correlations: [CrossSourceCorrelation]) async -> [CorrelationConfidenceScore]
}

final class ConfidenceScoringUseCase: ConfidenceScoringUseCaseProtocol {
    func execute(correlations: [CrossSourceCorrelation]) async -> [CorrelationConfidenceScore] {
        correlations.map { correlation in
            let r = max(-0.999_999, min(0.999_999, correlation.pearson))
            let effectSize = abs((2 * r) / sqrt(1 - (r * r)))
            let confidence = confidenceLevel(effectSize: effectSize, sampleSize: correlation.sampleSize)

            return CorrelationConfidenceScore(
                id: UUID(),
                lhsMetric: correlation.lhsMetric,
                rhsMetric: correlation.rhsMetric,
                confidence: confidence,
                effectSize: effectSize,
                sampleSize: correlation.sampleSize
            )
        }
    }

    private func confidenceLevel(effectSize: Double, sampleSize: Int) -> Insight.ConfidenceLevel {
        guard sampleSize >= AppConstants.Health.minDataDaysForInsight else { return .low }

        switch effectSize {
        case ..<0.3:
            return .low
        case 0.3..<0.6:
            return .medium
        default:
            return .high
        }
    }
}
