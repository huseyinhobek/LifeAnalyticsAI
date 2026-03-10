// MARK: - Presentation.Screens.Insights

import SwiftUI

struct CorrelationAnalysisView: View {
    @StateObject private var viewModel: CorrelationAnalysisViewModel

    init(viewModel: CorrelationAnalysisViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                TimePeriodPicker(selected: $viewModel.selectedPeriod)

                if viewModel.isLoading && viewModel.cards.isEmpty {
                    LoadingStateView(
                        title: "chart.collecting".localized,
                        subtitle: "report.loading_subtitle".localized,
                        icon: "chart.xyaxis.line"
                    )
                }

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                }

                if viewModel.cards.isEmpty, !viewModel.isLoading, viewModel.errorMessage == nil {
                    ChartEmptyState(
                        title: "chart.collecting".localized,
                        message: "chart.collecting_detail".localized(with: AppConstants.Health.minDataDaysForInsight, 0),
                        daysRequired: AppConstants.Health.minDataDaysForInsight,
                        daysCollected: 0
                    )
                }

                ForEach(viewModel.cards) { card in
                    CorrelationScatterChart(
                        title: card.title,
                        insight: card.insight,
                        result: card.result,
                        xLabel: card.xLabel,
                        yLabel: card.yLabel,
                        xColor: card.xColor,
                        yColor: card.yColor
                    )
                }
            }
            .padding(Theme.paddingLarge)
        }
        .background(Color("BackgroundLight"))
        .navigationTitle("dashboard.correlation_analysis".localized)
        .task { await viewModel.load() }
        .onChange(of: viewModel.selectedPeriod) { _, _ in
            Task { await viewModel.refresh() }
        }
        .refreshable { await viewModel.refresh() }
        .premiumGate(.crossCorrelation)
    }
}
