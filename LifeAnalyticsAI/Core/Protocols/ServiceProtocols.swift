// MARK: - Core.Protocols

import Foundation

protocol CalendarServiceProtocol {
    func requestAccess() async throws -> Bool
    func fetchEvents(from: Date, to: Date) async throws -> [CalendarEvent]
    func getDailySummary(for date: Date) async throws -> DailySummary
    func getWeeklyMeetingAnalysis(for weekStart: Date) async throws -> WeeklyMeetingAnalysis
}

protocol NotificationServiceProtocol {
    func requestPermission() async throws -> Bool
    func scheduleMorning(at components: DateComponents, streakDays: Int) async throws
    func scheduleEvening(at components: DateComponents, moodCheckInsThisWeek: Int) async throws
    func scheduleWeekly(at components: DateComponents, trackedDays: Int) async throws
    func cancelAll() async
}

protocol InsightEngineProtocol {
    func analyzeCorrelations() async throws -> [Insight]
    func detectAnomalies() async throws -> [Insight]
    func findSeasonality() async throws -> [Insight]
    func generateDailyInsight(for date: Date) async throws -> Insight?
    func generateWeeklyReport(for weekStart: Date) async throws -> WeeklyReport
}

protocol LLMServiceProtocol {
    func generateInsightExplanation(insight: Insight, languageCode: String) async -> String
    func generateWeeklyReport(report: WeeklyReport, languageCode: String) async -> String
    func generatePrediction(prediction: PredictionResult, languageCode: String) async -> String
}

protocol PromptFeedbackOptimizing {
    func recordFeedback(for insight: Insight, feedback: Insight.UserFeedback)
}
