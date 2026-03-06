// MARK: - Data.DataSources.AI

import Foundation

final class AnthropicLLMService: LLMServiceProtocol {
    private let sendRequest: @Sendable (_ prompt: String, _ systemPrompt: String) async throws -> String
    private let promptTemplateManager: PromptTemplateManager

    init(
        promptTemplateManager: PromptTemplateManager = PromptTemplateManager(),
        sendRequest: @escaping @Sendable (_ prompt: String, _ systemPrompt: String) async throws -> String = { prompt, systemPrompt in
            try await NetworkManager.shared.sendLLMRequest(prompt: prompt, systemPrompt: systemPrompt)
        }
    ) {
        self.promptTemplateManager = promptTemplateManager
        self.sendRequest = sendRequest
    }

    func generateInsightExplanation(insight: Insight, languageCode: String) async -> String {
        let template = promptTemplateManager.makeInsightExplanationTemplate(insight: insight, languageCode: languageCode)

        do {
            return try await sendRequest(template.userPrompt, template.systemPrompt)
        } catch {
            return fallbackInsightText(for: insight, languageCode: languageCode)
        }
    }

    func generateWeeklyReport(report: WeeklyReport, languageCode: String) async -> String {
        let template = promptTemplateManager.makeWeeklyReportTemplate(report: report, languageCode: languageCode)

        do {
            return try await sendRequest(template.userPrompt, template.systemPrompt)
        } catch {
            return fallbackWeeklyText(for: report, languageCode: languageCode)
        }
    }

    func generatePrediction(prediction: PredictionResult, languageCode: String) async -> String {
        let template = promptTemplateManager.makePredictionTemplate(prediction: prediction, languageCode: languageCode)

        do {
            return try await sendRequest(template.userPrompt, template.systemPrompt)
        } catch {
            return fallbackPredictionText(for: prediction, languageCode: languageCode)
        }
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
