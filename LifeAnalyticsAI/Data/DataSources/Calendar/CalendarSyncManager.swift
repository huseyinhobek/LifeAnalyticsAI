// MARK: - Data.DataSources.Calendar

import Foundation

final class CalendarSyncManager {
    private let calendarRepository: CalendarRepositoryProtocol
    private let defaults: UserDefaults
    private let now: () -> Date
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let lastSyncDate = "calendar.lastSyncDate"
        static let cachedEvents = "calendar.cachedEvents"
    }

    init(
        calendarRepository: CalendarRepositoryProtocol,
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.calendarRepository = calendarRepository
        self.defaults = defaults
        self.now = now
    }

    @discardableResult
    func syncEvents(daysBack: Int = 30) async throws -> Int {
        let endDate = now()
        let startDate = lastCalendarSyncDate ?? Calendar.current.date(byAdding: .day, value: -max(daysBack, 1), to: endDate) ?? endDate
        let fetchedEvents = try await calendarRepository.fetchEvents(from: startDate, to: endDate)

        guard !fetchedEvents.isEmpty else {
            defaults.set(endDate, forKey: Keys.lastSyncDate)
            AppLogger.health.info("Calendar sync finished: no new events")
            return 0
        }

        let merged = merge(existing: cachedEvents, with: fetchedEvents)
        let data = try encoder.encode(merged)
        defaults.set(data, forKey: Keys.cachedEvents)
        defaults.set(endDate, forKey: Keys.lastSyncDate)
        AppLogger.health.info("Calendar sync finished: \(fetchedEvents.count) fetched, \(merged.count) cached")
        return fetchedEvents.count
    }

    var lastCalendarSyncDate: Date? {
        defaults.object(forKey: Keys.lastSyncDate) as? Date
    }

    var cachedEvents: [CalendarEvent] {
        guard let data = defaults.data(forKey: Keys.cachedEvents) else { return [] }
        return (try? decoder.decode([CalendarEvent].self, from: data)) ?? []
    }

    func cachedEvents(from: Date, to: Date) -> [CalendarEvent] {
        cachedEvents.filter { event in
            event.startDate >= from && event.startDate <= to
        }
    }

    private func merge(existing: [CalendarEvent], with incoming: [CalendarEvent]) -> [CalendarEvent] {
        var indexed: [String: CalendarEvent] = [:]

        for event in existing {
            indexed[eventKey(event)] = event
        }

        for event in incoming {
            indexed[eventKey(event)] = event
        }

        return indexed.values.sorted { $0.startDate < $1.startDate }
    }

    private func eventKey(_ event: CalendarEvent) -> String {
        let calendarName = event.calendarName ?? ""
        return "\(event.title)|\(event.startDate.timeIntervalSince1970)|\(event.endDate.timeIntervalSince1970)|\(calendarName)"
    }
}
