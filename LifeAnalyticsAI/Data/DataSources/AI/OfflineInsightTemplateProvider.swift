// MARK: - Data.DataSources.AI

import Foundation

protocol OfflineFallbackGenerating {
    func insightText(for insight: Insight, languageCode: String) -> String
    func weeklyReportText(for report: WeeklyReport, languageCode: String) -> String
    func predictionText(for prediction: PredictionResult, languageCode: String) -> String
}

struct OfflineInsightTemplateProvider: OfflineFallbackGenerating {
    func insightText(for insight: Insight, languageCode: String) -> String {
        if isTurkish(languageCode) {
            return "Cevrimdisi ozet (\(localizedInsightType(insight.type, turkish: true))): \(insight.title). \(insight.body) Guven: \(insight.confidenceLevel.label)."
        }
        return "Offline summary (\(localizedInsightType(insight.type, turkish: false))): \(insight.title). \(insight.body) Confidence: \(insight.confidenceLevel.rawValue)."
    }

    func weeklyReportText(for report: WeeklyReport, languageCode: String) -> String {
        if isTurkish(languageCode) {
            return "Cevrimdisi haftalik ozet: \(report.summary) Toplam \(report.insights.count) icgoru degerlendirildi."
        }
        return "Offline weekly summary: \(report.summary) Evaluated \(report.insights.count) insights."
    }

    func predictionText(for prediction: PredictionResult, languageCode: String) -> String {
        if isTurkish(languageCode) {
            return "Cevrimdisi tahmin: Yarin mood \(format(prediction.predictedMoodNextDay)), gelecek hafta ortalamasi \(format(prediction.predictedMoodNextWeekAverage)). Guven: \(prediction.confidence.label)."
        }
        return "Offline prediction: Mood is \(format(prediction.predictedMoodNextDay)) tomorrow and \(format(prediction.predictedMoodNextWeekAverage)) next week on average. Confidence: \(prediction.confidence.rawValue)."
    }

    private func isTurkish(_ languageCode: String) -> Bool {
        languageCode.lowercased().hasPrefix("tr")
    }

    private func localizedInsightType(_ type: Insight.InsightType, turkish: Bool) -> String {
        if !turkish {
            return type.rawValue
        }

        switch type {
        case .correlation:
            return "korelasyon"
        case .anomaly:
            return "anomali"
        case .prediction:
            return "tahmin"
        case .trend:
            return "trend"
        case .seasonal:
            return "donemsellik"
        }
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
