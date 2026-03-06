// MARK: - Data.DataSources.Calendar

import EventKit
import Foundation

final class EventKitCalendarService: CalendarServiceProtocol {
    private let eventStore: EKEventStore

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    func requestAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .fullAccess, .writeOnly:
            return true
        case .notDetermined:
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                guard granted else { throw AppError.calendarAccessDenied }
                return true
            } else {
                let granted: Bool = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                    eventStore.requestAccess(to: .event) { accessGranted, error in
                        if let error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(returning: accessGranted)
                    }
                }
                guard granted else { throw AppError.calendarAccessDenied }
                return true
            }
        case .denied, .restricted:
            throw AppError.calendarAccessDenied
        @unknown default:
            throw AppError.calendarAccessDenied
        }
    }

    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent] {
        _ = try await requestAccess()
        return []
    }

    func getDailySummary(for date: Date) async throws -> DailySummary {
        _ = try await requestAccess()
        return DailySummary(date: date.startOfDay, totalMeetings: 0, totalMeetingMinutes: 0, freeHours: 24, busiestHour: nil)
    }
}
