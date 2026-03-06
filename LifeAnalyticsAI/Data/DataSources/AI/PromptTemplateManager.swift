// MARK: - Data.DataSources.AI

import Foundation

struct PromptTemplate {
    let systemPrompt: String
    let userPrompt: String
}

final class PromptTemplateManager: PromptFeedbackOptimizing {
    private let feedbackStore: PromptFeedbackStore

    init(feedbackStore: PromptFeedbackStore = PromptFeedbackStore()) {
        self.feedbackStore = feedbackStore
    }

    func recordFeedback(for insight: Insight, feedback: Insight.UserFeedback) {
        feedbackStore.recordFeedback(type: insight.type, feedback: feedback)
    }

    func makeInsightExplanationTemplate(insight: Insight, languageCode: String) -> PromptTemplate {
        PromptTemplate(
            systemPrompt: systemPrompt(languageCode: languageCode, insightType: insight.type),
            userPrompt: """
            Gorev: Tek bir anonimlestirilmis icgoru acikla.
            Cikti: 2-3 cumle, net ve uygulanabilir.

            Veri:
            - Tip: \(insight.type.rawValue)
            - Baslik: \(insight.title)
            - Aciklama: \(insight.body)
            - Guven: \(insight.confidenceLevel.rawValue)
            - Ilgili metrik ozetleri: \(metricSummary(insight.relatedMetrics))
            """
        )
    }

    func makeWeeklyReportTemplate(report: WeeklyReport, languageCode: String) -> PromptTemplate {
        PromptTemplate(
            systemPrompt: systemPrompt(languageCode: languageCode, insightType: nil),
            userPrompt: """
            Gorev: Haftalik anonimlestirilmis paternleri kullanarak rapor yaz.
            Cikti: 3 kisa bolum (Ozet, Gozlem, Oneri).

            Veri:
            - Hafta baslangici: \(isoDate(report.weekStartDate))
            - Ozet: \(report.summary)
            - Insight sayisi: \(report.insights.count)
            - One cikan insightlar: \(insightSummary(report.insights))
            - Ana metrikler: \(metricSummary(report.keyMetrics))
            - Tahmin: \(report.prediction ?? "yok")
            """
        )
    }

    func makePredictionTemplate(prediction: PredictionResult, languageCode: String) -> PromptTemplate {
        PromptTemplate(
            systemPrompt: systemPrompt(languageCode: languageCode, insightType: .prediction),
            userPrompt: """
            Gorev: Anonimlestirilmis tahmin degerlerinden kisa ongoru metni uret.
            Cikti: 2 cumle, abartisiz ve net.

            Veri:
            - Ertesi gun tahmini mood: \(format(prediction.predictedMoodNextDay))
            - Gelecek hafta ortalama mood: \(format(prediction.predictedMoodNextWeekAverage))
            - Guven: \(prediction.confidence.rawValue)
            """
        )
    }

    private func systemPrompt(languageCode: String, insightType: Insight.InsightType?) -> String {
        let locale = languageCode.lowercased().hasPrefix("tr") ? "Turkce" : "English"
        let optimizationHint = feedbackStore.optimizationHint(for: insightType)
        return """
        You are a wellness analytics assistant. Write in \(locale).
        Use only anonymized pattern summaries. Do not ask for personal identifiers.
        Keep explanations practical, neutral, and concise.
        Prompt optimization hint: \(optimizationHint)
        """
    }

    private func insightSummary(_ insights: [Insight]) -> String {
        let top = insights.prefix(3)
        guard !top.isEmpty else { return "yok" }
        return top.map { "\($0.type.rawValue):\($0.confidenceLevel.rawValue)" }.joined(separator: ", ")
    }

    private func metricSummary(_ metrics: [MetricReference]) -> String {
        let top = metrics.prefix(5)
        guard !top.isEmpty else { return "yok" }
        return top.map { metric in
            "\(metric.name)=\(format(metric.value)) \(metric.unit)"
        }.joined(separator: ", ")
    }

    private func isoDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
