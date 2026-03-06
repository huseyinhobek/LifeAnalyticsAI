// MARK: - Presentation.ViewModels

import Foundation

@MainActor
final class InsightDetailViewModel: ObservableObject {
    @Published private(set) var insight: Insight
    @Published private(set) var selectedFeedback: Insight.UserFeedback?
    @Published private(set) var isSavingFeedback = false
    @Published var errorMessage: String?

    private let updateInsightFeedbackUseCase: UpdateInsightFeedbackUseCaseProtocol

    init(insight: Insight, updateInsightFeedbackUseCase: UpdateInsightFeedbackUseCaseProtocol) {
        self.insight = insight
        self.updateInsightFeedbackUseCase = updateInsightFeedbackUseCase
        self.selectedFeedback = insight.userFeedback
    }

    func sendFeedback(_ feedback: Insight.UserFeedback) async {
        guard !isSavingFeedback else { return }
        isSavingFeedback = true
        defer { isSavingFeedback = false }

        do {
            try await updateInsightFeedbackUseCase.execute(insight: insight, feedback: feedback)
            selectedFeedback = feedback
            insight.userFeedback = feedback
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var metricChartData: [MetricChartPoint] {
        insight.relatedMetrics.map {
            MetricChartPoint(name: $0.name, value: $0.value, trend: $0.trend)
        }
    }
}

struct MetricChartPoint: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let trend: MetricReference.Trend
}
