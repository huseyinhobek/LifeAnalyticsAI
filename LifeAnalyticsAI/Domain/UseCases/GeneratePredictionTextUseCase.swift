// MARK: - Domain.UseCases

import Foundation

protocol GeneratePredictionTextUseCaseProtocol {
    func execute(for referenceDate: Date) async throws -> String?
}

final class GeneratePredictionTextUseCase: GeneratePredictionTextUseCaseProtocol {
    private let sleepRepository: SleepRepositoryProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let calendarRepository: CalendarRepositoryProtocol
    private let normalizer: NormalizeTimeSeriesDataUseCaseProtocol
    private let predictionEngine: PredictionEngineUseCaseProtocol
    private let llmService: LLMServiceProtocol
    private let languageCodeProvider: @Sendable () -> String

    init(
        sleepRepository: SleepRepositoryProtocol,
        moodRepository: MoodRepositoryProtocol,
        calendarRepository: CalendarRepositoryProtocol,
        normalizer: NormalizeTimeSeriesDataUseCaseProtocol = NormalizeTimeSeriesDataUseCase(),
        predictionEngine: PredictionEngineUseCaseProtocol = PredictionEngineUseCase(),
        llmService: LLMServiceProtocol,
        languageCodeProvider: @escaping @Sendable () -> String = { GeneratePredictionTextUseCase.defaultLanguageCode() }
    ) {
        self.sleepRepository = sleepRepository
        self.moodRepository = moodRepository
        self.calendarRepository = calendarRepository
        self.normalizer = normalizer
        self.predictionEngine = predictionEngine
        self.llmService = llmService
        self.languageCodeProvider = languageCodeProvider
    }

    func execute(for referenceDate: Date = Date()) async throws -> String? {
        let points = try await loadRecentPoints(referenceDate: referenceDate)
        guard let prediction = await predictionEngine.execute(points: points) else {
            return nil
        }

        let languageCode = languageCodeProvider()
        let text = await llmService.generatePrediction(prediction: prediction, languageCode: languageCode)
        return text.isEmpty ? nil : text
    }

    private func loadRecentPoints(referenceDate: Date) async throws -> [TimeSeriesDataPoint] {
        let end = referenceDate.endOfDay
        let start = end.daysAgo(30)

        async let sleep = sleepRepository.fetchSleepRecords(from: start, to: end)
        async let mood = moodRepository.fetchMoodEntries(from: start, to: end)
        async let calendar = calendarRepository.fetchEvents(from: start, to: end)

        return await normalizer.execute(
            sleepRecords: try sleep,
            moodEntries: try mood,
            calendarEvents: try calendar
        )
    }

    private static func defaultLanguageCode() -> String {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return preferred.hasPrefix("tr") ? "tr" : "en"
    }
}
