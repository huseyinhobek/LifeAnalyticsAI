// MARK: - Tests.MoodFeature

import XCTest
@testable import LifeAnalyticsAI

final class MoodFeatureTests: XCTestCase {
    func testSaveMoodEntryUseCasePersistsEntry() async throws {
        let repository = MockMoodRepository()
        let useCase = SaveMoodEntryUseCase(repository: repository)
        let entry = sampleMood(value: 4, dayOffset: 0)

        try await useCase.execute(entry)
        let count = await repository.count()

        XCTAssertEqual(count, 1)
    }

    func testMoodStatisticsCalculatorReturnsAverageAndUpTrend() async throws {
        let repository = MockMoodRepository()
        let calculator = MoodStatisticsCalculator(repository: repository)

        try await repository.saveMoodEntry(sampleMood(value: 2, dayOffset: 20))
        try await repository.saveMoodEntry(sampleMood(value: 2, dayOffset: 18))
        try await repository.saveMoodEntry(sampleMood(value: 4, dayOffset: 3))
        try await repository.saveMoodEntry(sampleMood(value: 5, dayOffset: 1))

        let average = try await calculator.averageMood(days: 30)
        let trend = try await calculator.moodTrend(weeks: 4)

        XCTAssertEqual(average, 3.25, accuracy: 0.001)
        if case .up = trend.direction {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected upward mood trend")
        }
        XCTAssertGreaterThan(trend.weeklyChange, 0)
    }

    @MainActor
    func testMoodEntryViewModelShowsValidationErrorWithoutMood() async {
        let repository = MockMoodRepository()
        let viewModel = MoodEntryViewModel(saveMoodEntryUseCase: SaveMoodEntryUseCase(repository: repository))

        await viewModel.saveEntry()

        XCTAssertEqual(viewModel.errorMessage, "Lutfen bir mood seciniz.")
        XCTAssertFalse(viewModel.didSave)
    }

    @MainActor
    func testMoodEntryViewModelSavesSelectedMood() async {
        let repository = MockMoodRepository()
        let viewModel = MoodEntryViewModel(saveMoodEntryUseCase: SaveMoodEntryUseCase(repository: repository))
        viewModel.selectedMoodLevel = .good
        viewModel.note = "Verimli bir gun"
        viewModel.toggleActivity(.work)

        await viewModel.saveEntry()

        let count = await repository.count()
        XCTAssertEqual(count, 1)
        XCTAssertTrue(viewModel.didSave)
        XCTAssertNil(viewModel.errorMessage)
    }

    private func sampleMood(value: Int, dayOffset: Int) -> MoodEntry {
        let timestamp = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
        return MoodEntry(
            id: UUID(),
            date: timestamp.startOfDay,
            timestamp: timestamp,
            value: value,
            note: nil,
            activities: [.work]
        )
    }
}
