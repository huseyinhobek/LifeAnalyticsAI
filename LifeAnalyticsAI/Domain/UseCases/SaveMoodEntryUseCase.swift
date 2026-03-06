// MARK: - Domain.UseCases

import Foundation

protocol SaveMoodEntryUseCaseProtocol {
    func execute(_ entry: MoodEntry) async throws
}

final class SaveMoodEntryUseCase: SaveMoodEntryUseCaseProtocol {
    private let repository: MoodRepositoryProtocol

    init(repository: MoodRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ entry: MoodEntry) async throws {
        try await repository.saveMoodEntry(entry)
    }
}
