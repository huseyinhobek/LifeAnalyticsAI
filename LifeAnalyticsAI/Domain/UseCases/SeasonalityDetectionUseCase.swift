// MARK: - Domain.UseCases

import Accelerate
import Foundation

struct SeasonalityDetectionResult: Codable, Hashable {
    let weekdayAverage: Double
    let weekendAverage: Double
    let mondayAverage: Double
    let strongestWeekday: Int
    let weakestWeekday: Int

    var weekendEffect: Double {
        weekendAverage - weekdayAverage
    }

    var mondaySyndromeStrength: Double {
        weekdayAverage - mondayAverage
    }
}

protocol SeasonalityDetectionUseCaseProtocol {
    func execute(points: [TimeSeriesDataPoint]) async -> SeasonalityDetectionResult?
}

final class SeasonalityDetectionUseCase: SeasonalityDetectionUseCaseProtocol {
    func execute(points: [TimeSeriesDataPoint]) async -> SeasonalityDetectionResult? {
        let moodPoints = points.filter { $0.metric == .moodScore }
        guard moodPoints.count >= AppConstants.Health.minDataDaysForInsight else { return nil }

        let groupedByWeekday = Dictionary(grouping: moodPoints, by: { Calendar.current.component(.weekday, from: $0.date) })
            .mapValues { dayPoints in
                vDSP.mean(dayPoints.map { $0.normalizedValue })
            }

        guard !groupedByWeekday.isEmpty else { return nil }

        let weekdayValues = groupedByWeekday
            .filter { key, _ in key != 1 && key != 7 }
            .map { $0.value }
        let weekendValues = [groupedByWeekday[1], groupedByWeekday[7]].compactMap { $0 }

        let weekdayAverage = weekdayValues.isEmpty ? 0 : vDSP.mean(weekdayValues)
        let weekendAverage = weekendValues.isEmpty ? 0 : vDSP.mean(weekendValues)
        let mondayAverage = groupedByWeekday[2] ?? weekdayAverage

        guard let strongest = groupedByWeekday.max(by: { $0.value < $1.value })?.key,
              let weakest = groupedByWeekday.min(by: { $0.value < $1.value })?.key else {
            return nil
        }

        return SeasonalityDetectionResult(
            weekdayAverage: weekdayAverage,
            weekendAverage: weekendAverage,
            mondayAverage: mondayAverage,
            strongestWeekday: strongest,
            weakestWeekday: weakest
        )
    }
}
