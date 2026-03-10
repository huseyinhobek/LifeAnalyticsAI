// MARK: - Tests.GeneratePredictionTextUseCase

import XCTest
@testable import LifeAnalyticsAI

final class GeneratePredictionTextUseCaseTests: XCTestCase {
    func testExecuteBuildsPredictionTextFromLLM() async throws {
        let useCase = GeneratePredictionTextUseCase(
            sleepRepository: StubSleepRepositoryForPrediction(),
            moodRepository: StubMoodRepositoryForPrediction(),
            calendarRepository: StubCalendarRepositoryForPrediction(),
            normalizer: StubNormalizerForPrediction(),
            predictionEngine: StubPredictionEngineForText(result: PredictionResult(predictedMoodNextDay: 3.6, predictedMoodNextWeekAverage: 3.9, confidence: .medium)),
            llmService: StubLLMServiceForPredictionText(response: "AI forecast message"),
            languageCodeProvider: { "en" }
        )

        let result = try await useCase.execute(for: Date())

        XCTAssertEqual(result, "AI forecast message")
    }

    func testExecuteReturnsNilWhenPredictionEngineHasNoResult() async throws {
        let useCase = GeneratePredictionTextUseCase(
            sleepRepository: StubSleepRepositoryForPrediction(),
            moodRepository: StubMoodRepositoryForPrediction(),
            calendarRepository: StubCalendarRepositoryForPrediction(),
            normalizer: StubNormalizerForPrediction(),
            predictionEngine: StubPredictionEngineForText(result: nil),
            llmService: StubLLMServiceForPredictionText(response: "unused"),
            languageCodeProvider: { "tr" }
        )

        let result = try await useCase.execute(for: Date())

        XCTAssertNil(result)
    }
}

private actor StubSleepRepositoryForPrediction: SleepRepositoryProtocol {
    func fetchSleepRecords(from: Date, to: Date) async throws -> [SleepRecord] {
        _ = from
        _ = to
        return []
    }

    func saveSleepRecord(_ record: SleepRecord) async throws {
        _ = record
    }

    func getAverageSleep(days: Int) async throws -> Double {
        _ = days
        return 0
    }
}

private actor StubMoodRepositoryForPrediction: MoodRepositoryProtocol {
    func saveMoodEntry(_ entry: MoodEntry) async throws {
        _ = entry
    }

    func fetchMoodEntries(from: Date, to: Date) async throws -> [MoodEntry] {
        _ = from
        _ = to
        return []
    }

    func getAverageMood(days: Int) async throws -> Double {
        _ = days
        return 0
    }
}

private actor StubCalendarRepositoryForPrediction: CalendarRepositoryProtocol {
    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent] {
        _ = from
        _ = to
        return []
    }

    func getDailySummary(for date: Date) async throws -> DailySummary {
        DailySummary(date: date.startOfDay, totalMeetings: 0, totalMeetingMinutes: 0, freeHours: 0, busiestHour: nil)
    }

    func getWeeklyMeetingAnalysis(for weekStart: Date) async throws -> WeeklyMeetingAnalysis {
        WeeklyMeetingAnalysis(
            weekStart: weekStart.startOfWeek,
            meetingCountByWeekday: [:],
            totalMeetings: 0,
            totalMeetingMinutes: 0,
            previousWeekMeetings: 0,
            weekOverWeekChange: 0
        )
    }
}

private struct StubNormalizerForPrediction: NormalizeTimeSeriesDataUseCaseProtocol {
    func execute(
        sleepRecords: [SleepRecord],
        moodEntries: [MoodEntry],
        calendarEvents: [CalendarEvent]
    ) async -> [TimeSeriesDataPoint] {
        _ = sleepRecords
        _ = moodEntries
        _ = calendarEvents
        return [
            TimeSeriesDataPoint(
                id: UUID(),
                date: Date().startOfDay,
                source: .mood,
                metric: .moodScore,
                rawValue: 3.5,
                normalizedValue: 0.625
            )
        ]
    }

    func normalizeSleepRecords(_ records: [SleepRecord]) async -> [TimeSeriesDataPoint] {
        _ = records
        return []
    }

    func normalizeMoodEntries(_ entries: [MoodEntry]) async -> [TimeSeriesDataPoint] {
        _ = entries
        return []
    }

    func normalizeCalendarEvents(_ events: [CalendarEvent]) async -> [TimeSeriesDataPoint] {
        _ = events
        return []
    }
}

private struct StubPredictionEngineForText: PredictionEngineUseCaseProtocol {
    let result: PredictionResult?

    func execute(points: [TimeSeriesDataPoint]) async -> PredictionResult? {
        _ = points
        return result
    }
}

private struct StubLLMServiceForPredictionText: LLMServiceProtocol {
    let response: String

    func generateInsightExplanation(insight: Insight, languageCode: String) async -> String {
        _ = insight
        _ = languageCode
        return response
    }

    func generateWeeklyReport(report: WeeklyReport, languageCode: String) async -> String {
        _ = report
        _ = languageCode
        return response
    }

    func generatePrediction(prediction: PredictionResult, languageCode: String) async -> String {
        _ = prediction
        _ = languageCode
        return response
    }
}
