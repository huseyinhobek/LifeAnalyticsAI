// MARK: - Tests.OfflineInsightTemplateProvider

import XCTest
@testable import LifeAnalyticsAI

final class OfflineInsightTemplateProviderTests: XCTestCase {
    func testTurkishInsightTemplateContainsOfflinePrefix() {
        let provider = OfflineInsightTemplateProvider()
        let text = provider.insightText(for: makeInsight(), languageCode: "tr")

        XCTAssertTrue(text.contains("Cevrimdisi ozet"))
        XCTAssertTrue(text.contains("korelasyon"))
    }

    func testEnglishWeeklyTemplateContainsInsightCount() {
        let provider = OfflineInsightTemplateProvider()
        let text = provider.weeklyReportText(for: makeWeeklyReport(), languageCode: "en")

        XCTAssertTrue(text.contains("Offline weekly summary"))
        XCTAssertTrue(text.contains("Evaluated"))
    }

    func testPredictionTemplateIncludesConfidence() {
        let provider = OfflineInsightTemplateProvider()
        let text = provider.predictionText(
            for: PredictionResult(predictedMoodNextDay: 3.4, predictedMoodNextWeekAverage: 3.7, confidence: .high),
            languageCode: "tr"
        )

        XCTAssertTrue(text.contains("Cevrimdisi tahmin"))
        XCTAssertTrue(text.contains("Guven"))
    }

    private func makeInsight() -> Insight {
        Insight(
            id: UUID(),
            date: Date(),
            type: .correlation,
            title: "Uyku ve mood iliskisi",
            body: "Daha uzun uyku ile mood artisi gozleniyor.",
            confidenceLevel: .high,
            relatedMetrics: [],
            userFeedback: nil
        )
    }

    private func makeWeeklyReport() -> WeeklyReport {
        WeeklyReport(
            id: UUID(),
            weekStartDate: Date().startOfWeek,
            summary: "Stabil trend",
            insights: [makeInsight()],
            keyMetrics: [],
            prediction: nil
        )
    }
}
