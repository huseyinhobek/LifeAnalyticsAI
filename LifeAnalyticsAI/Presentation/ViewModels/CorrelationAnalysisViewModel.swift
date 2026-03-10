// MARK: - Presentation.ViewModels

import Foundation
import SwiftUI

@MainActor
final class CorrelationAnalysisViewModel: ObservableObject {
    struct CorrelationCard: Identifiable {
        let id = UUID()
        let title: String
        let insight: String
        let result: CorrelationResult
        let xLabel: String
        let yLabel: String
        let xColor: Color
        let yColor: Color
    }

    @Published private(set) var cards: [CorrelationCard] = []
    @Published private(set) var isLoading = false
    @Published var selectedPeriod: ChartStyleGuide.TimePeriod = .month30
    @Published var errorMessage: String?

    private let sleepRepository: SleepRepositoryProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let calendarRepository: CalendarRepositoryProtocol
    private let normalizeUseCase: NormalizeTimeSeriesDataUseCaseProtocol
    private let crossSourceAnalysisUseCase: CrossSourceAnalysisUseCaseProtocol
    private let confidenceScoringUseCase: ConfidenceScoringUseCaseProtocol
    private let significanceCalculator: CorrelationSignificanceCalculatorProtocol

    init(
        sleepRepository: SleepRepositoryProtocol,
        moodRepository: MoodRepositoryProtocol,
        calendarRepository: CalendarRepositoryProtocol,
        normalizeUseCase: NormalizeTimeSeriesDataUseCaseProtocol,
        crossSourceAnalysisUseCase: CrossSourceAnalysisUseCaseProtocol,
        confidenceScoringUseCase: ConfidenceScoringUseCaseProtocol,
        significanceCalculator: CorrelationSignificanceCalculatorProtocol
    ) {
        self.sleepRepository = sleepRepository
        self.moodRepository = moodRepository
        self.calendarRepository = calendarRepository
        self.normalizeUseCase = normalizeUseCase
        self.crossSourceAnalysisUseCase = crossSourceAnalysisUseCase
        self.confidenceScoringUseCase = confidenceScoringUseCase
        self.significanceCalculator = significanceCalculator
    }

    func load() async {
        if isLoading { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        let endDate = Date().endOfDay
        let startDate = endDate.daysAgo(selectedPeriod.days - 1).startOfDay

        do {
            async let sleepRecords = sleepRepository.fetchSleepRecords(from: startDate, to: endDate)
            async let moodEntries = moodRepository.fetchMoodEntries(from: startDate, to: endDate)
            async let calendarEvents = calendarRepository.fetchEvents(from: startDate, to: endDate)

            let (sleep, mood, events) = try await (sleepRecords, moodEntries, calendarEvents)
            let points = await normalizeUseCase.execute(
                sleepRecords: sleep,
                moodEntries: mood,
                calendarEvents: events
            )

            let correlations = await crossSourceAnalysisUseCase.execute(points: points)
            let confidenceScores = await confidenceScoringUseCase.execute(correlations: correlations)

            cards = await buildCards(from: points, correlations: correlations, confidence: confidenceScores)
            errorMessage = nil
        } catch {
            cards = []
            errorMessage = error.localizedDescription
        }
    }

    private func buildCards(
        from points: [TimeSeriesDataPoint],
        correlations: [CrossSourceCorrelation],
        confidence: [CorrelationConfidenceScore]
    ) async -> [CorrelationCard] {
        let targetPairs: [(TimeSeriesDataPoint.Metric, TimeSeriesDataPoint.Metric, String, String, Color, Color)] = [
            (.sleepHours, .moodScore, "Uyku", "Mood", ChartStyleGuide.SemanticColor.sleep, ChartStyleGuide.SemanticColor.mood),
            (.meetingMinutes, .sleepHours, "Toplanti Dakika", "Uyku", ChartStyleGuide.SemanticColor.meetings, ChartStyleGuide.SemanticColor.sleep)
        ]

        var built: [CorrelationCard] = []

        for (lhs, rhs, xLabel, yLabel, xColor, yColor) in targetPairs {
            guard let corr = correlations.first(where: { $0.lhsMetric == lhs && $0.rhsMetric == rhs }) else { continue }
            let paired = pairedPoints(points: points, lhs: lhs, rhs: rhs)
            guard paired.count >= 2 else { continue }

            let regression = linearRegression(for: paired)
            let pValueResult = await significanceCalculator.execute(
                correlation: corr.pearson,
                sampleSize: corr.sampleSize,
                alpha: AppConstants.Health.pValueThreshold
            )
            let pValue = pValueResult?.pValue ?? 1

            let confidenceLevel = confidence
                .first(where: { $0.lhsMetric == lhs && $0.rhsMetric == rhs })
                .map { mapConfidence($0.confidence) } ?? .low

            let result = CorrelationResult(
                points: paired,
                rValue: corr.pearson,
                pValue: pValue,
                sampleSize: corr.sampleSize,
                regressionSlope: regression.slope,
                regressionIntercept: regression.intercept,
                confidence: confidenceLevel
            )

            let insight = String(
                format: "r=%.2f · p=%@",
                corr.pearson,
                pValue < 0.001 ? "<0.001" : String(format: "%.3f", pValue)
            )

            built.append(
                CorrelationCard(
                    title: "\(xLabel) vs \(yLabel)",
                    insight: insight,
                    result: result,
                    xLabel: xLabel,
                    yLabel: yLabel,
                    xColor: xColor,
                    yColor: yColor
                )
            )
        }

        return built
    }

    private func pairedPoints(
        points: [TimeSeriesDataPoint],
        lhs: TimeSeriesDataPoint.Metric,
        rhs: TimeSeriesDataPoint.Metric
    ) -> [CorrelationPoint] {
        let lhsGrouped = Dictionary(grouping: points.filter { $0.metric == lhs }, by: { $0.date.startOfDay })
        let rhsGrouped = Dictionary(grouping: points.filter { $0.metric == rhs }, by: { $0.date.startOfDay })

        let dates = Set(lhsGrouped.keys).intersection(rhsGrouped.keys).sorted()

        return dates.compactMap { day in
            guard let lhsValues = lhsGrouped[day]?.map(\.rawValue),
                  let rhsValues = rhsGrouped[day]?.map(\.rawValue),
                  !lhsValues.isEmpty,
                  !rhsValues.isEmpty else {
                return nil
            }

            let x = lhsValues.reduce(0, +) / Double(lhsValues.count)
            let y = rhsValues.reduce(0, +) / Double(rhsValues.count)

            return CorrelationPoint(
                xValue: x,
                yValue: y,
                date: day,
                xLabel: lhs.rawValue,
                yLabel: rhs.rawValue
            )
        }
    }

    private func linearRegression(for points: [CorrelationPoint]) -> (slope: Double, intercept: Double) {
        let n = Double(points.count)
        guard n > 1 else { return (0, 0) }

        let sumX = points.map(\.xValue).reduce(0, +)
        let sumY = points.map(\.yValue).reduce(0, +)
        let sumXY = points.map { $0.xValue * $0.yValue }.reduce(0, +)
        let sumX2 = points.map { $0.xValue * $0.xValue }.reduce(0, +)

        let denominator = (n * sumX2) - (sumX * sumX)
        guard denominator != 0 else { return (0, sumY / n) }

        let slope = ((n * sumXY) - (sumX * sumY)) / denominator
        let intercept = (sumY - (slope * sumX)) / n
        return (slope, intercept)
    }

    private func mapConfidence(_ confidence: Insight.ConfidenceLevel) -> ChartStyleGuide.ConfidenceLevel {
        switch confidence {
        case .low:
            return .low
        case .medium:
            return .medium
        case .high:
            return .high
        }
    }
}
