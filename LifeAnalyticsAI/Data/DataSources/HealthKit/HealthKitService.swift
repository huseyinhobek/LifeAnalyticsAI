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
        return true
    }

    func isAuthorized() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func fetchSleepData(from: Date, to: Date) async throws -> [SleepRecord] {
        try ensureAuthorized()

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw AppError.dataNotFound
        }

        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )

        let samples = try await descriptor.result(for: healthStore)
        if samples.isEmpty { return [] }

        var grouped: [Date: SleepNightAggregate] = [:]

        for sample in samples {
            let bucketDate = sleepBucketDate(for: sample.startDate)
            var aggregate = grouped[bucketDate] ?? SleepNightAggregate(date: bucketDate)

            let minutes = max(0, Calendar.current.dateComponents([.minute], from: sample.startDate, to: sample.endDate).minute ?? 0)
            aggregate.bedtime = min(aggregate.bedtime ?? sample.startDate, sample.startDate)
            aggregate.wakeTime = max(aggregate.wakeTime ?? sample.endDate, sample.endDate)

            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                aggregate.inBedMinutes += minutes
            case HKCategoryValueSleepAnalysis.asleep.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                aggregate.asleepMinutes += minutes
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                aggregate.awakeMinutes += minutes
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                aggregate.asleepMinutes += minutes
                aggregate.coreMinutes += minutes
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                aggregate.asleepMinutes += minutes
                aggregate.deepMinutes += minutes
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                aggregate.asleepMinutes += minutes
                aggregate.remMinutes += minutes
            default:
                break
            }

            grouped[bucketDate] = aggregate
        }

        return grouped.values
            .compactMap { aggregate in
                guard let bedtime = aggregate.bedtime, let wakeTime = aggregate.wakeTime else {
                    return nil
                }

                let asleep = max(aggregate.asleepMinutes, aggregate.deepMinutes + aggregate.remMinutes + aggregate.coreMinutes)
                let inBed = max(aggregate.inBedMinutes, asleep)
                let lightMinutes = max(0, (aggregate.coreMinutes > 0 ? aggregate.coreMinutes : asleep - aggregate.deepMinutes - aggregate.remMinutes))
                let efficiency = inBed > 0 ? min(1, max(0, Double(asleep) / Double(inBed))) : nil

                return SleepRecord(
                    id: UUID(),
                    date: aggregate.date,
                    bedtime: bedtime,
                    wakeTime: wakeTime,
                    totalMinutes: asleep,
                    deepSleepMinutes: aggregate.deepMinutes > 0 ? aggregate.deepMinutes : nil,
                    remSleepMinutes: aggregate.remMinutes > 0 ? aggregate.remMinutes : nil,
                    lightSleepMinutes: lightMinutes > 0 ? lightMinutes : nil,
                    efficiency: efficiency,
                    source: .healthKit
                )
            }
            .sorted(by: { $0.date > $1.date })
    }

    func fetchStepCount(for date: Date) async throws -> Int {
        try ensureAuthorized()

        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw AppError.dataNotFound
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: date.startOfDay,
            end: date.endOfDay,
            options: [.strictStartDate, .strictEndDate]
        )

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
                continuation.resume(returning: max(0, Int(steps.rounded())))
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

    private func sleepBucketDate(for date: Date) -> Date {
        let hour = Calendar.current.component(.hour, from: date)
        let baseDate = hour < 12 ? date.daysAgo(1) : date
        return baseDate.startOfDay
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

private struct SleepNightAggregate {
    let date: Date
    var bedtime: Date?
    var wakeTime: Date?
    var inBedMinutes = 0
    var asleepMinutes = 0
    var awakeMinutes = 0
    var deepMinutes = 0
    var remMinutes = 0
    var coreMinutes = 0
}
