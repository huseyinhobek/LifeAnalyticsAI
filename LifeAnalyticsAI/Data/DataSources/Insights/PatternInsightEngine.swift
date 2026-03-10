// MARK: - Data.DataSources.Insights

import Foundation

final class PatternInsightEngine: InsightEngineProtocol {
    private let sleepRepository: SleepRepositoryProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let calendarRepository: CalendarRepositoryProtocol

    private let normalizer: NormalizeTimeSeriesDataUseCaseProtocol
    private let crossSourceAnalysis: CrossSourceAnalysisUseCaseProtocol
    private let confidenceScoring: ConfidenceScoringUseCaseProtocol
    private let anomalyDetection: AnomalyDetectionUseCaseProtocol
    private let seasonalityDetection: SeasonalityDetectionUseCaseProtocol
    private let bestDayProfile: BestDayProfileUseCaseProtocol
    private let predictionEngine: PredictionEngineUseCaseProtocol
    private let prioritization: InsightPrioritizationUseCaseProtocol

    init(
        sleepRepository: SleepRepositoryProtocol,
        moodRepository: MoodRepositoryProtocol,
        calendarRepository: CalendarRepositoryProtocol,
        normalizer: NormalizeTimeSeriesDataUseCaseProtocol = NormalizeTimeSeriesDataUseCase(),
        crossSourceAnalysis: CrossSourceAnalysisUseCaseProtocol = CrossSourceAnalysisUseCase(),
        confidenceScoring: ConfidenceScoringUseCaseProtocol = ConfidenceScoringUseCase(),
        anomalyDetection: AnomalyDetectionUseCaseProtocol = AnomalyDetectionUseCase(),
        seasonalityDetection: SeasonalityDetectionUseCaseProtocol = SeasonalityDetectionUseCase(),
        bestDayProfile: BestDayProfileUseCaseProtocol = BestDayProfileUseCase(),
        predictionEngine: PredictionEngineUseCaseProtocol = PredictionEngineUseCase(),
        prioritization: InsightPrioritizationUseCaseProtocol = InsightPrioritizationUseCase()
    ) {
        self.sleepRepository = sleepRepository
        self.moodRepository = moodRepository
        self.calendarRepository = calendarRepository
        self.normalizer = normalizer
        self.crossSourceAnalysis = crossSourceAnalysis
        self.confidenceScoring = confidenceScoring
        self.anomalyDetection = anomalyDetection
        self.seasonalityDetection = seasonalityDetection
        self.bestDayProfile = bestDayProfile
        self.predictionEngine = predictionEngine
        self.prioritization = prioritization
    }

    func analyzeCorrelations() async throws -> [Insight] {
        let points = try await loadRecentPoints()
        let correlations = await crossSourceAnalysis.execute(points: points)
        let confidenceScores = await confidenceScoring.execute(correlations: correlations)

        return confidenceScores.map { score in
            Insight(
                id: UUID(),
                date: Date(),
                type: .correlation,
                title: "insight.correlation.title".localized,
                body: "insight.correlation.body".localized(with: score.lhsMetric.rawValue, score.rhsMetric.rawValue),
                confidenceLevel: score.confidence,
                relatedMetrics: [
                    MetricReference(name: score.lhsMetric.rawValue, value: score.effectSize, unit: "metric.unit.effect".localized, trend: .stable),
                    MetricReference(name: score.rhsMetric.rawValue, value: Double(score.sampleSize), unit: "metric.unit.sample".localized, trend: .stable)
                ],
                userFeedback: nil
            )
        }
    }

    func detectAnomalies() async throws -> [Insight] {
        let points = try await loadRecentPoints()
        let anomalies = await anomalyDetection.execute(
            points: points,
            threshold: AppConstants.Health.anomalyZScoreThreshold
        )

        return anomalies.map { anomaly in
            let trend: MetricReference.Trend = anomaly.direction == .high ? .up : .down
            return Insight(
                id: UUID(),
                date: anomaly.date,
                type: .anomaly,
                title: "insight.anomaly.title".localized,
                body: "insight.anomaly.body".localized(with: anomaly.metric.rawValue, String(format: "%.2f", anomaly.zScore)),
                confidenceLevel: .high,
                relatedMetrics: [
                    MetricReference(name: anomaly.metric.rawValue, value: anomaly.value, unit: "metric.unit.raw".localized, trend: trend)
                ],
                userFeedback: nil
            )
        }
    }

    func findSeasonality() async throws -> [Insight] {
        let points = try await loadRecentPoints()
        guard let seasonality = await seasonalityDetection.execute(points: points) else { return [] }

        let insight = Insight(
            id: UUID(),
            date: Date(),
            type: .seasonal,
            title: "insight.seasonal.title".localized,
            body: "insight.seasonal.body".localized(with: String(format: "%.2f", seasonality.weekendEffect), String(format: "%.2f", seasonality.mondaySyndromeStrength)),
            confidenceLevel: .medium,
            relatedMetrics: [
                MetricReference(name: "WeekendEffect", value: seasonality.weekendEffect, unit: "metric.unit.mood".localized, trend: seasonality.weekendEffect >= 0 ? .up : .down),
                MetricReference(name: "MondaySyndrome", value: seasonality.mondaySyndromeStrength, unit: "metric.unit.mood".localized, trend: seasonality.mondaySyndromeStrength >= 0 ? .down : .up)
            ],
            userFeedback: nil
        )

        return [insight]
    }

    func generateDailyInsight(for date: Date) async throws -> Insight? {
        let correlationInsights = try await analyzeCorrelations()
        let anomalyInsights = try await detectAnomalies().filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let seasonalInsights = try await findSeasonality()

        let combined = anomalyInsights + correlationInsights + seasonalInsights
        let prioritized = await prioritization.execute(insights: combined, top: 1)
        return prioritized.first?.insight
    }

    func generateWeeklyReport(for weekStart: Date) async throws -> WeeklyReport {
        let points = try await loadRecentPoints(referenceDate: weekStart)
        let correlations = try await analyzeCorrelations()
        let anomalies = try await detectAnomalies()
        let seasonal = try await findSeasonality()
        let prioritized = await prioritization.execute(insights: correlations + anomalies + seasonal, top: 5)

        let profile = await bestDayProfile.execute(points: points)
        let prediction = await predictionEngine.execute(points: points)

        var keyMetrics: [MetricReference] = []
        if let profile {
            keyMetrics.append(MetricReference(name: "BestDayMood", value: profile.averageMood, unit: "metric.unit.score".localized, trend: .up))
            keyMetrics.append(MetricReference(name: "BestDaySleep", value: profile.averageSleepHours, unit: "metric.unit.hour".localized, trend: .up))
        }
        if let prediction {
            keyMetrics.append(MetricReference(name: "NextWeekMood", value: prediction.predictedMoodNextWeekAverage, unit: "metric.unit.score".localized, trend: .stable))
        }

        let predictionText: String?
        if let prediction {
            predictionText = "report.prediction.next_day".localized(with: String(format: "%.2f", prediction.predictedMoodNextDay))
        } else {
            predictionText = nil
        }

        return WeeklyReport(
            id: UUID(),
            weekStartDate: weekStart.startOfWeek,
            summary: "report.summary.generated".localized,
            insights: prioritized.map { $0.insight },
            keyMetrics: keyMetrics,
            prediction: predictionText
        )
    }

    private func loadRecentPoints(referenceDate: Date = Date()) async throws -> [TimeSeriesDataPoint] {
        let end = referenceDate.endOfDay
        let start = end.daysAgo(AppConstants.Health.patternWindowDays)

        async let sleep = sleepRepository.fetchSleepRecords(from: start, to: end)
        async let mood = moodRepository.fetchMoodEntries(from: start, to: end)
        async let calendar = calendarRepository.fetchEvents(from: start, to: end)

        let points = await normalizer.execute(
            sleepRecords: try sleep,
            moodEntries: try mood,
            calendarEvents: try calendar
        )

        return points
    }
}
