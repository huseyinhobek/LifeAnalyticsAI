// MARK: - Core.Protocols

import Foundation

protocol CalendarServiceProtocol {
    func requestAccess() async throws -> Bool
    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent]
    func getDailySummary(for date: Date) async throws -> DailySummary
    func getWeeklyMeetingAnalysis(for weekStart: Date) async throws -> WeeklyMeetingAnalysis
}

protocol NotificationServiceProtocol {
    func requestAuthorization() async throws
    func scheduleDailyMoodReminder(at components: DateComponents) async throws
}

protocol InsightEngineProtocol {
    func analyzeCorrelations() async throws -> [Insight]
    func detectAnomalies() async throws -> [Insight]
    func findSeasonality() async throws -> [Insight]
    func generateDailyInsight(for date: Date) async throws -> Insight?
    func generateWeeklyReport(for weekStart: Date) async throws -> WeeklyReport
}
