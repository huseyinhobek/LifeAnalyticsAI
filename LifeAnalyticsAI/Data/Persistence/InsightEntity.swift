// MARK: - Data.Persistence

import Foundation
import OSLog
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
        let insightType = Insight.InsightType(rawValue: type) ?? {
            AppLogger.insight.warning("Unknown insight type '\(self.type)', falling back to trend")
            return .trend
        }()

        let confidence = Insight.ConfidenceLevel(rawValue: confidenceLevel) ?? {
            AppLogger.insight.warning("Unknown confidence level '\(self.confidenceLevel)', falling back to medium")
            return .medium
        }()

        return Insight(
            id: id,
            date: date,
            type: insightType,
            title: title,
            body: body,
            confidenceLevel: confidence,
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
        JSONCoding.encodeToString(metrics, fallback: "[]", logger: AppLogger.insight, context: "MetricReference")
    }

    private static func decodeMetrics(from json: String) -> [MetricReference] {
        JSONCoding.decodeFromString([MetricReference].self, from: json, fallback: [], logger: AppLogger.insight, context: "MetricReference")
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
        JSONCoding.encodeToString(insights, fallback: "[]", logger: AppLogger.insight, context: "Insight")
    }

    private static func decodeInsights(from json: String) -> [Insight] {
        JSONCoding.decodeFromString([Insight].self, from: json, fallback: [], logger: AppLogger.insight, context: "Insight")
    }

    private static func encodeMetrics(_ metrics: [MetricReference]) -> String {
        JSONCoding.encodeToString(metrics, fallback: "[]", logger: AppLogger.insight, context: "MetricReference")
    }

    private static func decodeMetrics(from json: String) -> [MetricReference] {
        JSONCoding.decodeFromString([MetricReference].self, from: json, fallback: [], logger: AppLogger.insight, context: "MetricReference")
    }
}

enum JSONCoding {
    static func encodeToString<T: Encodable>(
        _ value: T,
        fallback: String,
        logger: Logger,
        context: String
    ) -> String {
        do {
            let data = try JSONEncoder().encode(value)
            guard let json = String(data: data, encoding: .utf8) else {
                logger.error("\(context) JSON encoding produced non-UTF8 output")
                return fallback
            }
            return json
        } catch {
            logger.error("\(context) JSON encoding failed: \(error.localizedDescription)")
            return fallback
        }
    }

    static func decodeFromString<T: Decodable>(
        _ type: T.Type,
        from json: String,
        fallback: T,
        logger: Logger,
        context: String
    ) -> T {
        guard let data = json.data(using: .utf8) else {
            logger.warning("\(context) JSON decode input is not UTF8")
            return fallback
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            logger.warning("\(context) JSON decode failed: \(error.localizedDescription)")
            return fallback
        }
    }
}
