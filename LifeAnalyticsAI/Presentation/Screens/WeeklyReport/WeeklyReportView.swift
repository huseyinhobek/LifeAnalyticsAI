// MARK: - Presentation.Screens.WeeklyReport

import Charts
import SwiftUI

struct WeeklyReportView: View {
    @StateObject private var viewModel: WeeklyReportViewModel
    @Bindable var router: NavigationRouter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(viewModel: WeeklyReportViewModel, router: NavigationRouter) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                if viewModel.isLoading && viewModel.selectedReport == nil {
                    LoadingStateView(
                        title: "Haftalik rapor hazirlaniyor",
                        subtitle: "AI ozet ve metrik kartlari yukleniyor",
                        icon: "doc.text.magnifyingglass"
                    )
                }

                if let report = viewModel.selectedReport {
                    summaryCard(report)
                    metricsSection(report)
                    insightsSection(report)
                }

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                }
            }
            .padding(Theme.paddingLarge)
        }
        .background(Color("BackgroundLight").opacity(0.35))
        .navigationTitle("Haftalik Rapor")
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
    }

    private func summaryCard(_ report: WeeklyReport) -> some View {
        return VStack(alignment: .leading, spacing: 10) {
            Label(
                report.weekStartDate.formatted(date: .abbreviated, time: .omitted),
                systemImage: "doc.text.image"
            )
            .font(Theme.captionFont)
            .foregroundStyle(Color("SecondaryBlue"))

            Text("AI Haftalik Ozeti")
                .font(Theme.titleFont)
                .foregroundStyle(Color("TextPrimary"))

            markdownText(report.summary)

            if let prediction = report.prediction, !prediction.isEmpty {
                Text("Tahmin: \(prediction)")
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private func metricsSection(_ report: WeeklyReport) -> some View {
        let safeMetrics = report.keyMetrics
            .filter { $0.value.isFinite && !$0.value.isNaN }
            .map { metric in
                MetricReference(name: metric.name, value: max(0, metric.value), unit: metric.unit, trend: metric.trend)
            }

        return VStack(alignment: .leading, spacing: 10) {
            Label("Metrik Kartlari", systemImage: "square.grid.2x2")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            if safeMetrics.isEmpty {
                EmptyStateView(
                    title: "Metrik karti bulunamadi",
                    subtitle: "Raporu yenileyerek yeniden deneyebilirsin.",
                    icon: "chart.bar.xaxis"
                )
            } else {
                Chart(safeMetrics.prefix(6), id: \.name) { metric in
                    BarMark(
                        x: .value("Metrik", metric.name),
                        y: .value("Deger", metric.value)
                    )
                    .foregroundStyle(color(for: metric.trend))
                    .cornerRadius(6)
                }
                .frame(height: horizontalSizeClass == .regular ? 260 : 190)
                .padding(12)
                .background(Color("BackgroundLight"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
        }
    }

    private func insightsSection(_ report: WeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Haftalik Icgoruler", systemImage: "lightbulb.max")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            if report.insights.isEmpty {
                EmptyStateView(
                    title: "Bu hafta icgoru bulunamadi",
                    subtitle: "Yeni veriler geldikce icgoruler otomatik olusacak.",
                    icon: "lightbulb.slash"
                )
            } else {
                ForEach(report.insights) { insight in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            router.navigate(to: .insightDetail(insight))
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(insight.title)
                                .font(.headline)
                                .foregroundStyle(Color("TextPrimary"))
                            Text(insight.body)
                                .font(Theme.captionFont)
                                .foregroundStyle(Color("TextSecondary"))
                                .lineLimit(2)
                            Text("Guven: \(insight.confidenceLevel.label)")
                                .font(Theme.captionFont)
                                .foregroundStyle(Color("SecondaryBlue"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.paddingMedium)
                        .background(Color("BackgroundLight"))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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

    @ViewBuilder
    private func markdownText(_ value: String) -> some View {
        let normalized = WeeklyReportTextFormatter.normalizedMarkdown(value)

        if let attributed = try? AttributedString(
            markdown: normalized,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            Text(attributed)
                .foregroundStyle(Color("TextPrimary"))
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(normalized)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
