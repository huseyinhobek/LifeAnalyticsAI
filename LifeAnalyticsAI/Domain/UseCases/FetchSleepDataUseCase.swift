// MARK: - Domain.UseCases

import Foundation

protocol FetchSleepDataUseCaseProtocol {
    func execute(days: Int) async throws -> [SleepRecord]
}

final class FetchSleepDataUseCase: FetchSleepDataUseCaseProtocol {
    private let repository: SleepRepositoryProtocol

    init(repository: SleepRepositoryProtocol) {
        self.repository = repository
    }

    func execute(days: Int) async throws -> [SleepRecord] {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end
        return try await repository.fetchSleepRecords(from: start, to: end)
    }
}
