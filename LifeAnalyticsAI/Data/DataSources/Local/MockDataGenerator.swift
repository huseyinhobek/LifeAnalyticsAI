// MARK: - Data.DataSources.Local

import Foundation

final class MockDataGenerator {
    static func generateSleepRecords(days: Int) -> [SleepRecord] {
        guard days > 0 else { return [] }

        let calendar = Calendar.current
        let today = Date().startOfDay

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }

            let isWeekend = date.isWeekend
            let baseMinutes = isWeekend ? Int.random(in: 420...540) : Int.random(in: 300...510)
            let bedtimeHour = isWeekend ? Int.random(in: 22...24) : Int.random(in: 21...23)
            let bedtimeMinute = [0, 15, 30, 45].randomElement() ?? 0

            var bedtimeComponents = calendar.dateComponents([.year, .month, .day], from: date)
            bedtimeComponents.hour = bedtimeHour == 24 ? 0 : bedtimeHour
            bedtimeComponents.minute = bedtimeMinute
            bedtimeComponents.second = 0

            let bedtimeBase = calendar.date(from: bedtimeComponents) ?? date
            let bedtime = bedtimeHour == 24
                ? calendar.date(byAdding: .day, value: 1, to: bedtimeBase) ?? bedtimeBase
                : bedtimeBase

            let wakeTime = calendar.date(byAdding: .minute, value: baseMinutes, to: bedtime) ?? bedtime

            let deepSleep = Int(Double(baseMinutes) * Double.random(in: 0.18...0.25))
            let remSleep = Int(Double(baseMinutes) * Double.random(in: 0.18...0.24))
            let lightSleep = max(0, baseMinutes - deepSleep - remSleep)
            let efficiency = min(1.0, max(0.6, Double(baseMinutes) / 540.0 + Double.random(in: -0.08...0.08)))

            return SleepRecord(
                id: UUID(),
                date: date,
                bedtime: bedtime,
                wakeTime: wakeTime,
                totalMinutes: baseMinutes,
                deepSleepMinutes: deepSleep,
                remSleepMinutes: remSleep,
                lightSleepMinutes: lightSleep,
                efficiency: efficiency,
                source: .manual
            )
        }
        .sorted(by: { $0.date < $1.date })
    }

    static func generateMoodEntries(days: Int) -> [MoodEntry] {
        let sleepByDay = Dictionary(uniqueKeysWithValues: generateSleepRecords(days: days).map { ($0.date.startOfDay, $0.totalHours) })
        let calendar = Calendar.current
        let today = Date().startOfDay

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }

            let sleepHours = sleepByDay[date.startOfDay] ?? 7.0
            let sleepScore = min(2, max(-1, Int((sleepHours - 6.5).rounded())))
            let weekendBoost = date.isWeekend ? 1 : 0
            let noise = Int.random(in: -1...1)
            let value = min(AppConstants.Mood.scaleMax, max(AppConstants.Mood.scaleMin, 3 + sleepScore + weekendBoost + noise))

            let availableTags: [ActivityTag] = date.isWeekend
                ? [.social, .nature, .family, .travel, .reading]
                : [.work, .exercise, .meditation, .reading, .social]

            let count = Int.random(in: 1...3)
            let activities = Array(availableTags.shuffled().prefix(count))
            let timestamp = calendar.date(byAdding: .hour, value: Int.random(in: 18...22), to: date) ?? date

            return MoodEntry(
                id: UUID(),
                date: date,
                timestamp: timestamp,
                value: value,
                note: value >= 4 ? "Gun iyi gecti" : (value <= 2 ? "Yorgunluk hissedildi" : nil),
                activities: activities
            )
        }
        .sorted(by: { $0.timestamp < $1.timestamp })
    }

    static func generateCalendarEvents(days: Int) -> [CalendarEvent] {
        guard days > 0 else { return [] }

        let calendar = Calendar.current
        let today = Date().startOfDay
        var events: [CalendarEvent] = []

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            let meetingsPerDay = day.isWeekend ? Int.random(in: 0...1) : Int.random(in: 3...7)
            for _ in 0..<meetingsPerDay {
                let startHour = day.isWeekend ? Int.random(in: 10...17) : Int.random(in: 9...18)
                let minute = [0, 15, 30, 45].randomElement() ?? 0
                let duration = [30, 45, 60, 90].randomElement() ?? 45

                var comps = calendar.dateComponents([.year, .month, .day], from: day)
                comps.hour = startHour
                comps.minute = minute
                comps.second = 0

                let startDate = calendar.date(from: comps) ?? day
                let endDate = calendar.date(byAdding: .minute, value: duration, to: startDate) ?? startDate

                events.append(
                    CalendarEvent(
                        id: UUID(),
                        title: day.isWeekend ? "Sosyal Plan" : "Toplanti",
                        startDate: startDate,
                        endDate: endDate,
                        isAllDay: false,
                        calendarName: day.isWeekend ? "Personal" : "Work"
                    )
                )
            }
        }

        return events.sorted(by: { $0.startDate < $1.startDate })
    }

    static func generateInsights() -> [Insight] {
        [
            Insight(
                id: UUID(),
                date: Date(),
                type: .correlation,
                title: "Uyku ve Ruh Hali Iliskisi",
                body: "7.5 saatin ustundeki uyku gunlerinde ruh hali puanin ortalama 0.8 daha yuksek.",
                confidenceLevel: .high,
                relatedMetrics: [
                    MetricReference(name: "Uyku Suresi", value: 7.8, unit: "saat", trend: .up),
                    MetricReference(name: "Mood Skoru", value: 4.1, unit: "puan", trend: .up)
                ],
                userFeedback: nil
            ),
            Insight(
                id: UUID(),
                date: Date().daysAgo(1),
                type: .trend,
                title: "Hafta Sonu Etkisi",
                body: "Hafta sonlarinda mood puanin hafta icine gore ortalama 0.6 daha yuksek.",
                confidenceLevel: .medium,
                relatedMetrics: [
                    MetricReference(name: "Hafta Sonu Mood", value: 4.3, unit: "puan", trend: .up),
                    MetricReference(name: "Hafta Ici Mood", value: 3.7, unit: "puan", trend: .stable)
                ],
                userFeedback: nil
            )
        ]
    }
}
