// MARK: - Tests.PromptTemplateManager

import XCTest
@testable import LifeAnalyticsAI

final class PromptTemplateManagerTests: XCTestCase {
    func testInsightTemplateSeparatesSystemAndUserPrompt() {
        let manager = PromptTemplateManager()
        let template = manager.makeInsightExplanationTemplate(insight: makeInsight(), languageCode: "tr")

        XCTAssertTrue(template.systemPrompt.contains("anonymized pattern summaries"))
        XCTAssertTrue(template.userPrompt.contains("Gorev: Tek bir anonimlestirilmis icgoru acikla"))
        XCTAssertTrue(template.userPrompt.contains("Tip:"))
    }

    func testWeeklyTemplateContainsOnlyAggregateFields() {
        let manager = PromptTemplateManager()
        let template = manager.makeWeeklyReportTemplate(report: makeWeeklyReport(), languageCode: "en")

        XCTAssertTrue(template.userPrompt.contains("Insight sayisi"))
        XCTAssertTrue(template.userPrompt.contains("Ana metrikler"))
        XCTAssertFalse(template.userPrompt.contains("timestamp"))
        XCTAssertFalse(template.userPrompt.contains("id:"))
    }

    func testPredictionTemplateIncludesConfidenceAndValues() {
        let manager = PromptTemplateManager()
        let prediction = PredictionResult(predictedMoodNextDay: 3.25, predictedMoodNextWeekAverage: 3.75, confidence: .medium)

        let template = manager.makePredictionTemplate(prediction: prediction, languageCode: "tr")

        XCTAssertTrue(template.userPrompt.contains("3.25"))
        XCTAssertTrue(template.userPrompt.contains("3.75"))
        XCTAssertTrue(template.userPrompt.contains("Guven: medium"))
    }

    private func makeInsight() -> Insight {
        Insight(
            id: UUID(),
            date: Date(),
            type: .anomaly,
            title: "Anomali",
            body: "Beklenmeyen degisim tespit edildi.",
            confidenceLevel: .high,
            relatedMetrics: [MetricReference(name: "Mood", value: 2.1, unit: "puan", trend: .down)],
            userFeedback: nil
        )
    }

    private func makeWeeklyReport() -> WeeklyReport {
        WeeklyReport(
            id: UUID(),
            weekStartDate: Date().startOfWeek,
            summary: "Hafta dengeli",
            insights: [makeInsight()],
            keyMetrics: [MetricReference(name: "NextWeekMood", value: 3.8, unit: "puan", trend: .stable)],
            prediction: "Yarin mood 3.6"
        )
    }
}
