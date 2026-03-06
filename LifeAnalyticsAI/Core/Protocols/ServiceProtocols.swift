// MARK: - Core.Protocols

import Foundation

protocol CalendarServiceProtocol {
    func requestAccess() async throws
}

protocol NotificationServiceProtocol {
    func requestAuthorization() async throws
}

protocol InsightEngineProtocol {
    func generateInsights() async throws -> [Insight]
}
