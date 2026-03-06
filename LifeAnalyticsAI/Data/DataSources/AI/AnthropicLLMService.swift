// MARK: - Data.DataSources.AI

import Foundation

final class AnthropicLLMService: LLMServiceProtocol {
    private let sendRequest: @Sendable (_ prompt: String, _ systemPrompt: String) async throws -> String

    init(
        sendRequest: @escaping @Sendable (_ prompt: String, _ systemPrompt: String) async throws -> String = { prompt, systemPrompt in
            try await NetworkManager.shared.sendLLMRequest(prompt: prompt, systemPrompt: systemPrompt)
        }
    ) {
        self.sendRequest = sendRequest
    }

    func generateInsightExplanation(insight: Insight, languageCode: String) async -> String {
        let systemPrompt = buildSystemPrompt(languageCode: languageCode)
        let prompt = """
        Gorev: Tek bir anonimlestirilmis icgoru acikla.
        Cikti: 2-3 cumle, net ve uygulanabilir.

        Veri:
        - Tip: \(insight.type.rawValue)
        - Baslik: \(insight.title)
        - Aciklama: \(insight.body)
        - Guven: \(insight.confidenceLevel.rawValue)
        - Ilgili metrik ozetleri: \(metricSummary(insight.relatedMetrics))
        """

        do {
            return try await sendRequest(prompt, systemPrompt)
        } catch {
            return fallbackInsightText(for: insight, languageCode: languageCode)
        }
    }

    func generateWeeklyReport(report: WeeklyReport, languageCode: String) async -> String {
        let systemPrompt = buildSystemPrompt(languageCode: languageCode)
        let prompt = """
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

        do {
            return try await sendRequest(prompt, systemPrompt)
        } catch {
            return fallbackWeeklyText(for: report, languageCode: languageCode)
        }
    }

    func generatePrediction(prediction: PredictionResult, languageCode: String) async -> String {
        let systemPrompt = buildSystemPrompt(languageCode: languageCode)
        let prompt = """
        Gorev: Anonimlestirilmis tahmin degerlerinden kisa ongoru metni uret.
        Cikti: 2 cumle, abartisiz ve net.

        Veri:
        - Ertesi gun tahmini mood: \(format(prediction.predictedMoodNextDay))
        - Gelecek hafta ortalama mood: \(format(prediction.predictedMoodNextWeekAverage))
        - Guven: \(prediction.confidence.rawValue)
        """

        do {
            return try await sendRequest(prompt, systemPrompt)
        } catch {
            return fallbackPredictionText(for: prediction, languageCode: languageCode)
        }
    }

    private func buildSystemPrompt(languageCode: String) -> String {
        let locale = languageCode.lowercased().hasPrefix("tr") ? "Turkce" : "English"
        return """
        You are a wellness analytics assistant. Write in \(locale).
        Use only anonymized pattern summaries. Do not ask for personal identifiers.
        Keep explanations practical, neutral, and concise.
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

    private func fallbackInsightText(for insight: Insight, languageCode: String) -> String {
        if languageCode.lowercased().hasPrefix("tr") {
            return "\(insight.title): \(insight.body) Guven duzeyi: \(insight.confidenceLevel.label)."
        }
        return "\(insight.title): \(insight.body) Confidence: \(insight.confidenceLevel.rawValue)."
    }

    private func fallbackWeeklyText(for report: WeeklyReport, languageCode: String) -> String {
        if languageCode.lowercased().hasPrefix("tr") {
            return "Haftalik ozet: \(report.summary) Toplam \(report.insights.count) icgoru degerlendirildi. Kucuk ve surdurulebilir adimlarla devam edin."
        }
        return "Weekly summary: \(report.summary) Evaluated \(report.insights.count) insights. Keep progress with small sustainable steps."
    }

    private func fallbackPredictionText(for prediction: PredictionResult, languageCode: String) -> String {
        if languageCode.lowercased().hasPrefix("tr") {
            return "Yarin tahmini mood \(format(prediction.predictedMoodNextDay)); gelecek hafta ortalamasi \(format(prediction.predictedMoodNextWeekAverage)). Guven: \(prediction.confidence.label)."
        }
        return "Estimated mood is \(format(prediction.predictedMoodNextDay)) tomorrow and \(format(prediction.predictedMoodNextWeekAverage)) for next week average. Confidence: \(prediction.confidence.rawValue)."
    }
}
