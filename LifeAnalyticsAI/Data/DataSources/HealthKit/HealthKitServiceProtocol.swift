// MARK: - Data.DataSources.HealthKit

import Foundation

protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func isAuthorized() -> Bool
    func fetchSleepData(from: Date, to: Date) async throws -> [SleepRecord]
    func fetchStepCount(for date: Date) async throws -> Int
    func fetchHeartRate(from: Date, to: Date) async throws -> [Double]
    func setupBackgroundDelivery() async throws
}
