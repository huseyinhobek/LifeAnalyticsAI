// MARK: - Domain.UseCases

import Foundation

protocol FetchMoodEntriesUseCaseProtocol {
    func execute(from: Date, to: Date) async throws -> [MoodEntry]
}

final class FetchMoodEntriesUseCase: FetchMoodEntriesUseCaseProtocol {
    private let repository: MoodRepositoryProtocol

    init(repository: MoodRepositoryProtocol) {
        self.repository = repository
    }

    func execute(from: Date, to: Date) async throws -> [MoodEntry] {
        try await repository.fetchMoodEntries(from: from, to: to)
    }
}
