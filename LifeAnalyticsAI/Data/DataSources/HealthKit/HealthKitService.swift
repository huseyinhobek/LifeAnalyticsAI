// MARK: - Data.DataSources.HealthKit

import Foundation
import HealthKit

final class HealthKitService: HealthKitServiceProtocol {
    private let healthStore = HKHealthStore()

    private let readTypes: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    ]

    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw AppError.healthKitNotAvailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)

        guard isAuthorized() else {
            throw AppError.healthKitAuthorizationDenied
        }

        return true
    }

    func isAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        return readTypes.allSatisfy { type in
            healthStore.authorizationStatus(for: type) == .sharingAuthorized
        }
    }

    func fetchSleepData(from: Date, to: Date) async throws -> [SleepRecord] {
        try ensureAuthorized()

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw AppError.dataNotFound
        }

        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let descriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples = try await queryCategorySamples(
            sampleType: sleepType,
            predicate: predicate,
            sortDescriptors: [descriptor]
        )

        return samples.map { sample in
            let totalMinutes = Calendar.current.dateComponents([.minute], from: sample.startDate, to: sample.endDate).minute ?? 0

            return SleepRecord(
                id: UUID(),
                date: sample.startDate.startOfDay,
                bedtime: sample.startDate,
                wakeTime: sample.endDate,
                totalMinutes: max(totalMinutes, 0),
                deepSleepMinutes: nil,
                remSleepMinutes: nil,
                lightSleepMinutes: nil,
                efficiency: nil,
                source: .healthKit
            )
        }
    }

    func fetchStepCount(for date: Date) async throws -> Int {
        try ensureAuthorized()

        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw AppError.dataNotFound
        }

        let predicate = HKQuery.predicateForSamples(withStart: date.startOfDay, end: date.endOfDay)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: AppError.unknown(underlying: error))
                    return
                }

                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }

            healthStore.execute(query)
        }
    }

    func fetchHeartRate(from: Date, to: Date) async throws -> [Double] {
        try ensureAuthorized()

        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw AppError.dataNotFound
        }

        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let descriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples = try await queryQuantitySamples(
            sampleType: heartRateType,
            predicate: predicate,
            sortDescriptors: [descriptor]
        )

        let unit = HKUnit.count().unitDivided(by: .minute())
        return samples.map { $0.quantity.doubleValue(for: unit) }
    }

    func setupBackgroundDelivery() async throws {
        try ensureAuthorized()

        for type in readTypes {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.enableBackgroundDelivery(for: type, frequency: .hourly) { success, error in
                    if let error {
                        continuation.resume(throwing: AppError.unknown(underlying: error))
                        return
                    }

                    guard success else {
                        continuation.resume(throwing: AppError.healthKitAuthorizationDenied)
                        return
                    }

                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func ensureAuthorized() throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw AppError.healthKitNotAvailable
        }

        guard isAuthorized() else {
            throw AppError.healthKitAuthorizationDenied
        }
    }

    private func queryCategorySamples(
        sampleType: HKCategoryType,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKCategorySample] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: AppError.unknown(underlying: error))
                    return
                }

                let typed = samples as? [HKCategorySample] ?? []
                continuation.resume(returning: typed)
            }

            healthStore.execute(query)
        }
    }

    private func queryQuantitySamples(
        sampleType: HKQuantityType,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKQuantitySample] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: AppError.unknown(underlying: error))
                    return
                }

                let typed = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: typed)
            }

            healthStore.execute(query)
        }
    }
}
