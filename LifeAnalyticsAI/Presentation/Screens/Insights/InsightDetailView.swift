// MARK: - Presentation.Screens.Insights

import Charts
import SwiftUI

struct InsightDetailView: View {
    @StateObject private var viewModel: InsightDetailViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
        VStack(alignment: .leading, spacing: 10) {
            Label("insight.detail.related_metrics".localized, systemImage: "chart.bar.xaxis")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            if viewModel.metricChartData.isEmpty {
                Text("insight.detail.no_related_metrics".localized)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Color("TextSecondary"))
            } else {
                Chart(viewModel.metricChartData) { point in
                    BarMark(
                        x: .value("Metrik", point.name),
                        y: .value("Deger", point.value)
                    )
                    .foregroundStyle(color(for: point.trend))
                    .cornerRadius(6)
                }
                .frame(height: horizontalSizeClass == .regular ? 260 : 200)
                .padding(12)
                .background(Color("BackgroundLight"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
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

    private func color(for trend: MetricReference.Trend) -> Color {
        switch trend {
        case .up:
            return Color("MoodGood")
        case .down:
            return Color("MoodBad")
        case .stable:
            return Color("SecondaryBlue")
        }
    }
}
