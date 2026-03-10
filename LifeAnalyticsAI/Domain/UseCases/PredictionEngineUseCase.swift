// MARK: - Domain.UseCases

import Accelerate
import Foundation

struct PredictionResult: Codable, Hashable {
    let predictedMoodNextDay: Double
    let predictedMoodNextWeekAverage: Double
    let confidence: Insight.ConfidenceLevel
}

protocol PredictionEngineUseCaseProtocol {
    func execute(points: [TimeSeriesDataPoint]) async -> PredictionResult?
}

final class PredictionEngineUseCase: PredictionEngineUseCaseProtocol {
    func execute(points: [TimeSeriesDataPoint]) async -> PredictionResult? {
        let moodPoints = points
            .filter { $0.metric == .moodScore }
            .sorted(by: { $0.date < $1.date })

        guard moodPoints.count >= AppConstants.Health.minDataDaysForInsight else { return nil }

        let values = moodPoints.map { $0.rawValue }
        let nextDay = linearPrediction(values)
        let nextWeek = values.suffix(7)
        let baseline = nextWeek.isEmpty ? nextDay : vDSP.mean(Array(nextWeek))

        let trendAdjustedWeek = (baseline + nextDay) / 2
        let confidence: Insight.ConfidenceLevel = moodPoints.count >= 28 ? .high : .medium

        return PredictionResult(
            predictedMoodNextDay: clampMood(nextDay),
            predictedMoodNextWeekAverage: clampMood(trendAdjustedWeek),
            confidence: confidence
        )
    }

    private func linearPrediction(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return values.last ?? 3.0 }

        let x = values.indices.map(Double.init)
        let xMean = vDSP.mean(x)
        let yMean = vDSP.mean(values)
        let centeredX = x.map { $0 - xMean }
        let centeredY = values.map { $0 - yMean }

        let slopeDenominator = vDSP.dot(centeredX, centeredX)
        guard slopeDenominator > 0 else { return yMean }

        let slope = vDSP.dot(centeredX, centeredY) / slopeDenominator
        let intercept = yMean - (slope * xMean)
        let nextX = Double(values.count)

        return intercept + (slope * nextX)
    }

    private func clampMood(_ value: Double) -> Double {
        min(Double(AppConstants.Mood.scaleMax), max(Double(AppConstants.Mood.scaleMin), value))
    }
}
