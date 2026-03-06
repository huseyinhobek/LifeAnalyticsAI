// MARK: - Domain.Repositories

import Foundation

protocol SleepRepositoryProtocol {
    func fetchSleepRecords(from: Date, to: Date) async throws -> [SleepRecord]
    func saveSleepRecord(_ record: SleepRecord) async throws
    func getAverageSleep(days: Int) async throws -> Double
}
