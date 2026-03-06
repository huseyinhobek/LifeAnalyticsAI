// MARK: - Domain.Repositories

import Foundation

protocol CalendarRepositoryProtocol {
    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent]
    func getDailySummary(for date: Date) async throws -> DailySummary
}
