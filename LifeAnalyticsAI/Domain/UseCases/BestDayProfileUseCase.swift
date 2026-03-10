// MARK: - Domain.UseCases

import Accelerate
import Foundation

struct BestDayProfile: Codable, Hashable {
    let dayOfWeek: Int
    let averageMood: Double
    let averageSleepHours: Double
    let averageMeetingMinutes: Double
}

protocol BestDayProfileUseCaseProtocol {
    func execute(points: [TimeSeriesDataPoint]) async -> BestDayProfile?
}

final class BestDayProfileUseCase: BestDayProfileUseCaseProtocol {
    func execute(points: [TimeSeriesDataPoint]) async -> BestDayProfile? {
        let moodByDay = aggregateByDay(points, metric: .moodScore)
        guard !moodByDay.isEmpty else { return nil }

        let sleepByDay = aggregateByDay(points, metric: .sleepHours)
        let meetingsByDay = aggregateByDay(points, metric: .meetingMinutes)

        let groupedByWeekday = Dictionary(grouping: moodByDay.keys, by: { Calendar.current.component(.weekday, from: $0) })
        var bestProfile: BestDayProfile?

        for (weekday, dates) in groupedByWeekday {
            let moodValues = dates.compactMap { moodByDay[$0] }
            guard !moodValues.isEmpty else { continue }

            let sleepValues = dates.compactMap { sleepByDay[$0] }
            let meetingValues = dates.compactMap { meetingsByDay[$0] }

            let profile = BestDayProfile(
                dayOfWeek: weekday,
                averageMood: vDSP.mean(moodValues),
                averageSleepHours: sleepValues.isEmpty ? 0 : vDSP.mean(sleepValues),
                averageMeetingMinutes: meetingValues.isEmpty ? 0 : vDSP.mean(meetingValues)
            )

            if let current = bestProfile {
                if profile.averageMood > current.averageMood {
                    bestProfile = profile
                }
            } else {
                bestProfile = profile
            }
        }

        return bestProfile
    }

    private func aggregateByDay(
        _ points: [TimeSeriesDataPoint],
        metric: TimeSeriesDataPoint.Metric
    ) -> [Date: Double] {
        let filtered = points.filter { $0.metric == metric }
        let grouped = Dictionary(grouping: filtered, by: { $0.date.startOfDay })

        return grouped.reduce(into: [Date: Double]()) { result, entry in
            let rawValues = entry.value.map { $0.rawValue }
            guard !rawValues.isEmpty else { return }
            result[entry.key] = vDSP.mean(rawValues)
        }
    }
}
