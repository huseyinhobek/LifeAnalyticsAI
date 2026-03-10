// MARK: - Domain.UseCases

import Accelerate
import Foundation

struct DetectedAnomaly: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let metric: TimeSeriesDataPoint.Metric
    let source: TimeSeriesDataPoint.Source
    let value: Double
    let zScore: Double
    let direction: Direction

    enum Direction: String, Codable {
        case high
        case low
    }
}

protocol AnomalyDetectionUseCaseProtocol {
    func execute(
        points: [TimeSeriesDataPoint],
        threshold: Double
    ) async -> [DetectedAnomaly]
}

final class AnomalyDetectionUseCase: AnomalyDetectionUseCaseProtocol {
    func execute(
        points: [TimeSeriesDataPoint],
        threshold: Double = AppConstants.Health.anomalyZScoreThreshold
    ) async -> [DetectedAnomaly] {
        let grouped = Dictionary(grouping: points, by: { MetricKey(source: $0.source, metric: $0.metric) })
        var anomalies: [DetectedAnomaly] = []

        for (key, metricPoints) in grouped {
            guard metricPoints.count >= 5 else { continue }

            let values = metricPoints.map(\.normalizedValue)
            let mean = vDSP.mean(values)

            let centered = values.map { $0 - mean }
            let squared = centered.map { $0 * $0 }
            let variance = vDSP.mean(squared)
            let standardDeviation = sqrt(variance)

            guard standardDeviation > 0 else { continue }

            for point in metricPoints {
                let zScore = (point.normalizedValue - mean) / standardDeviation
                guard abs(zScore) >= threshold else { continue }

                anomalies.append(
                    DetectedAnomaly(
                        id: UUID(),
                        date: point.date,
                        metric: key.metric,
                        source: key.source,
                        value: point.rawValue,
                        zScore: zScore,
                        direction: zScore >= 0 ? .high : .low
                    )
                )
            }
        }

        return anomalies.sorted(by: { $0.date < $1.date })
    }
}

private struct MetricKey: Hashable {
    let source: TimeSeriesDataPoint.Source
    let metric: TimeSeriesDataPoint.Metric
}
