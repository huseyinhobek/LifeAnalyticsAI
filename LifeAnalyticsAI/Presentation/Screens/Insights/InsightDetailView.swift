// MARK: - Presentation.Screens.Insights

import SwiftUI

struct InsightDetailView: View {
    @StateObject private var viewModel: InsightDetailViewModel
    init(viewModel: InsightDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                detailHeader
                relatedMetricsSection
                feedbackSection

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Theme.captionFont)
                        .foregroundStyle(Color("MoodBad"))
                }
            }
            .padding(Theme.paddingLarge)
        }
        .background(Color("BackgroundLight").opacity(0.35))
        .navigationTitle("insight.detail.nav_title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(viewModel.insight.type.rawValue.capitalized, systemImage: "lightbulb.max")
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("SecondaryBlue"))
                Spacer()
                Text("insight.detail.confidence".localized(with: viewModel.insight.confidenceLevel.label))
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("TextSecondary"))
            }

            Text(viewModel.insight.title)
                .font(Theme.titleFont)
                .foregroundStyle(Color("TextPrimary"))

            Text(viewModel.insight.body)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var relatedMetricsSection: some View {
        let sortedMetrics = viewModel.metricChartData
            .sorted { abs($0.value) > abs($1.value) }

        return VStack(alignment: .leading, spacing: 10) {
            Label("insight.detail.related_metrics".localized, systemImage: "chart.bar.xaxis")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            if sortedMetrics.isEmpty {
                Text("insight.detail.no_related_metrics".localized)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Color("TextSecondary"))
            } else if sortedMetrics.count == 1, let metric = sortedMetrics.first {
                singleMetricExecutiveTile(metric)
            } else {
                ComparisonBarChart(
                    title: "insight.detail.related_metrics".localized,
                    insight: insightForRelatedMetrics(sortedMetrics),
                    data: sortedMetrics.prefix(6).map { point in
                        ComparisonBarChart.BarDataPoint(
                            label: point.name,
                            value: point.value,
                            isHighlighted: point.trend != .stable,
                            comparisonValue: nil
                        )
                    },
                    color: ChartStyleGuide.SemanticColor.currentPeriod,
                    unit: ""
                )
            }
        }
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("insight.detail.helpful_question".localized, systemImage: "hand.thumbsup")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            HStack(spacing: 10) {
                feedbackButton(title: "insight.detail.feedback.helpful".localized, icon: "hand.thumbsup.fill", feedback: .helpful)
                feedbackButton(title: "insight.detail.feedback.improve".localized, icon: "hand.thumbsdown.fill", feedback: .notHelpful)
            }

            Text("insight.detail.feedback.hint".localized)
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private func feedbackButton(title: String, icon: String, feedback: Insight.UserFeedback) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {}
            Task { await viewModel.sendFeedback(feedback) }
        } label: {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(Theme.bodyFont)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(viewModel.selectedFeedback == feedback ? Color.white : Color("TextPrimary"))
            .background(viewModel.selectedFeedback == feedback ? Color("PrimaryBlue") : Color("BackgroundLight"))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Color("PrimaryBlue").opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSavingFeedback)
    }

    private func insightForRelatedMetrics(_ metrics: [MetricChartPoint]) -> String {
        guard let strongest = metrics.first else { return "" }
        let direction: String
        switch strongest.trend {
        case .up:
            direction = "chart.metric_direction_up".localized
        case .down:
            direction = "chart.metric_direction_down".localized
        case .stable:
            direction = "chart.metric_direction_stable".localized
        }

        return "\(readableMetricName(strongest.name)): \(String(format: "%.1f", strongest.value)) · \(direction)"
    }

    private func singleMetricExecutiveTile(_ metric: MetricChartPoint) -> some View {
        let accent: Color = {
            switch metric.trend {
            case .up: return ChartStyleGuide.SemanticColor.negative
            case .down: return ChartStyleGuide.SemanticColor.positive
            case .stable: return ChartStyleGuide.SemanticColor.neutral
            }
        }()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(readableMetricName(metric.name))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("TextPrimary"))

                Spacer()

                Text(metricTrendLabel(metric.trend))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accent.opacity(0.14))
                    .clipShape(Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", metric.value))
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(accent)
                Text("insight.detail.metric_value".localized)
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("TextSecondary"))
            }

            Text("insight.detail.single_metric_hint".localized)
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "121622"), accent.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
    }

    private func readableMetricName(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private func metricTrendLabel(_ trend: MetricReference.Trend) -> String {
        switch trend {
        case .up:
            return "chart.metric_direction_up".localized
        case .down:
            return "chart.metric_direction_down".localized
        case .stable:
            return "chart.metric_direction_stable".localized
        }
    }
}
