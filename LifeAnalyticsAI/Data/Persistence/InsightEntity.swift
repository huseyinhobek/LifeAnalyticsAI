// MARK: - Data.Persistence

import Foundation
import SwiftData

@Model
final class InsightEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var type: String
    var title: String
    var body: String
    var confidenceLevel: String
    var relatedMetricsJSON: String
    var userFeedback: String?
    var createdAt: Date

    init(
        id: UUID,
        date: Date,
        type: String,
        title: String,
        body: String,
        confidenceLevel: String,
        relatedMetricsJSON: String,
        userFeedback: String?,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.title = title
        self.body = body
        self.confidenceLevel = confidenceLevel
        self.relatedMetricsJSON = relatedMetricsJSON
        self.userFeedback = userFeedback
        self.createdAt = createdAt
    }

    func toDomain() -> Insight {
        Insight(
            id: id,
            date: date,
            type: Insight.InsightType(rawValue: type) ?? .trend,
            title: title,
            body: body,
            confidenceLevel: Insight.ConfidenceLevel(rawValue: confidenceLevel) ?? .medium,
            relatedMetrics: Self.decodeMetrics(from: relatedMetricsJSON),
            userFeedback: userFeedback.flatMap { Insight.UserFeedback(rawValue: $0) }
        )
    }

    static func fromDomain(_ insight: Insight) -> InsightEntity {
        InsightEntity(
            id: insight.id,
            date: insight.date,
            type: insight.type.rawValue,
            title: insight.title,
            body: insight.body,
            confidenceLevel: insight.confidenceLevel.rawValue,
            relatedMetricsJSON: encodeMetrics(insight.relatedMetrics),
            userFeedback: insight.userFeedback?.rawValue,
            createdAt: Date()
        )
    }

    private static func encodeMetrics(_ metrics: [MetricReference]) -> String {
        guard let data = try? JSONEncoder().encode(metrics),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    private static func decodeMetrics(from json: String) -> [MetricReference] {
        guard let data = json.data(using: .utf8),
              let metrics = try? JSONDecoder().decode([MetricReference].self, from: data) else {
            return []
        }
        return metrics
    }
}

@Model
final class WeeklyReportEntity {
    @Attribute(.unique) var id: UUID
    var weekStartDate: Date
    var summary: String
    var insightsJSON: String
    var keyMetricsJSON: String
    var prediction: String?
    var createdAt: Date

    init(
        id: UUID,
        weekStartDate: Date,
        summary: String,
        insightsJSON: String,
        keyMetricsJSON: String,
        prediction: String?,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.summary = summary
        self.insightsJSON = insightsJSON
        self.keyMetricsJSON = keyMetricsJSON
        self.prediction = prediction
        self.createdAt = createdAt
    }

    func toDomain() -> WeeklyReport {
        WeeklyReport(
            id: id,
            weekStartDate: weekStartDate,
            summary: summary,
            insights: Self.decodeInsights(from: insightsJSON),
            keyMetrics: Self.decodeMetrics(from: keyMetricsJSON),
            prediction: prediction
        )
    }

    static func fromDomain(_ report: WeeklyReport) -> WeeklyReportEntity {
        WeeklyReportEntity(
            id: report.id,
            weekStartDate: report.weekStartDate,
            summary: report.summary,
            insightsJSON: encodeInsights(report.insights),
            keyMetricsJSON: encodeMetrics(report.keyMetrics),
            prediction: report.prediction,
            createdAt: Date()
        )
    }

    private static func encodeInsights(_ insights: [Insight]) -> String {
        guard let data = try? JSONEncoder().encode(insights),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    private static func decodeInsights(from json: String) -> [Insight] {
        guard let data = json.data(using: .utf8),
              let insights = try? JSONDecoder().decode([Insight].self, from: data) else {
            return []
        }
        return insights
    }

    private static func encodeMetrics(_ metrics: [MetricReference]) -> String {
        guard let data = try? JSONEncoder().encode(metrics),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    private static func decodeMetrics(from json: String) -> [MetricReference] {
        guard let data = json.data(using: .utf8),
              let metrics = try? JSONDecoder().decode([MetricReference].self, from: data) else {
            return []
        }
        return metrics
    }
}
