// MARK: - Domain.UseCases

import Foundation

protocol SyncCalendarEventsUseCaseProtocol {
    func execute(daysBack: Int) async throws -> Int
}

final class SyncCalendarEventsUseCase: SyncCalendarEventsUseCaseProtocol {
    private let calendarSyncManager: CalendarSyncManager

    init(calendarSyncManager: CalendarSyncManager) {
        self.calendarSyncManager = calendarSyncManager
    }

    func execute(daysBack: Int = 30) async throws -> Int {
        try await calendarSyncManager.syncEvents(daysBack: daysBack)
    }
}
