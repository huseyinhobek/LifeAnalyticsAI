// MARK: - Domain.UseCases

import Foundation

struct CrossSourceCorrelation: Identifiable, Codable, Hashable {
    let id: UUID
    let lhsMetric: TimeSeriesDataPoint.Metric
    let rhsMetric: TimeSeriesDataPoint.Metric
    let pearson: Double
    let spearman: Double
    let sampleSize: Int
}

protocol CrossSourceAnalysisUseCaseProtocol {
    func execute(points: [TimeSeriesDataPoint]) async -> [CrossSourceCorrelation]
}

final class CrossSourceAnalysisUseCase: CrossSourceAnalysisUseCaseProtocol {
    private let pearsonCalculator: PearsonCorrelationCalculatorProtocol
    private let spearmanCalculator: SpearmanCorrelationCalculatorProtocol

    init(
        pearsonCalculator: PearsonCorrelationCalculatorProtocol = PearsonCorrelationCalculator(),
        spearmanCalculator: SpearmanCorrelationCalculatorProtocol = SpearmanCorrelationCalculator()
    ) {
        self.pearsonCalculator = pearsonCalculator
        self.spearmanCalculator = spearmanCalculator
    }

    func execute(points: [TimeSeriesDataPoint]) async -> [CrossSourceCorrelation] {
        let metricGroups = Dictionary(grouping: points, by: { $0.metric })
        let pairs: [(TimeSeriesDataPoint.Metric, TimeSeriesDataPoint.Metric)] = [
            (.sleepHours, .moodScore),
            (.meetingMinutes, .sleepHours),
            (.meetingCount, .moodScore)
        ]

        var results: [CrossSourceCorrelation] = []

        for (lhsMetric, rhsMetric) in pairs {
            guard let lhs = metricGroups[lhsMetric],
                  let rhs = metricGroups[rhsMetric] else {
                continue
            }

            async let pearson = pearsonCalculator.execute(lhs: lhs, rhs: rhs, minimumPoints: AppConstants.Health.minDataDaysForInsight)
            async let spearman = spearmanCalculator.execute(lhs: lhs, rhs: rhs, minimumPoints: AppConstants.Health.minDataDaysForInsight)

            guard let pearsonResult = await pearson,
                  let spearmanResult = await spearman else {
                continue
            }

            results.append(
                CrossSourceCorrelation(
                    id: UUID(),
                    lhsMetric: lhsMetric,
                    rhsMetric: rhsMetric,
                    pearson: pearsonResult.coefficient,
                    spearman: spearmanResult.coefficient,
                    sampleSize: min(pearsonResult.sampleSize, spearmanResult.sampleSize)
                )
            )
        }

        return results
    }
}
