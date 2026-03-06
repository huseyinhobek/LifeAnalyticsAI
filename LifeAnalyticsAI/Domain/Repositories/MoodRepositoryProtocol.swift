// MARK: - Domain.Repositories

import Foundation

protocol MoodRepositoryProtocol {
    func saveMoodEntry(_ entry: MoodEntry) async throws
    func fetchMoodEntries(from: Date, to: Date) async throws -> [MoodEntry]
    func getAverageMood(days: Int) async throws -> Double
}
