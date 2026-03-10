// MARK: - Presentation.Screens.Dashboard

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @Bindable var router: NavigationRouter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedPeriod: ChartStyleGuide.TimePeriod = .month30

    init(viewModel: DashboardViewModel, router: NavigationRouter) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                headerCard
                TimePeriodPicker(selected: $selectedPeriod)
                summaryCards

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                }

                if viewModel.isLoading && viewModel.sleepPoints.isEmpty {
                    LoadingStateView(
                        title: "dashboard.loading_title".localized,
                        subtitle: "dashboard.loading_subtitle".localized,
                        icon: "chart.bar.doc.horizontal"
                    )
                } else {
                    sleepChartSection
                    moodChartSection
                    activityChartSection
                }
            }
            .padding(Theme.paddingLarge)
        }
        .background(
            LinearGradient(
                colors: [Color("BackgroundLight"), Color("PrimaryBlue").opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("dashboard.nav_title".localized)
        .task {
            viewModel.selectedPeriod = selectedPeriod
            await viewModel.load()
        }
        .onChange(of: selectedPeriod) { _, newValue in
            viewModel.selectedPeriod = newValue
            Task { await viewModel.refresh() }
        }
        .refreshable { await viewModel.refresh() }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("dashboard.header.title".localized, systemImage: "chart.xyaxis.line")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("dashboard.header.subtitle".localized)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 8) {
                executiveChip(title: "Sleep", color: ChartStyleGuide.SemanticColor.sleep)
                executiveChip(title: "Mood", color: ChartStyleGuide.SemanticColor.mood)
                executiveChip(title: "Meetings", color: ChartStyleGuide.SemanticColor.meetings)
            }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    router.navigate(to: .weeklyReport(weekStart: Date().startOfWeek))
                }
            } label: {
                Label("dashboard.weekly_ai_report".localized, systemImage: "doc.text.image")
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("SecondaryBlue"))
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    router.navigate(to: .correlationAnalysis)
                }
            } label: {
                Label("dashboard.correlation_analysis".localized, systemImage: "chart.xyaxis.line")
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("SecondaryBlue"))
            }
            .buttonStyle(.plain)
            .premiumGate(.crossCorrelation)
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color("BackgroundLight"), Color("SecondaryBlue").opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color("SecondaryBlue").opacity(0.22), lineWidth: 1)
        )
    }

    private var summaryCards: some View {
        let columns: [GridItem] = horizontalSizeClass == .regular
            ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: Theme.paddingMedium) {
            summaryCard(
                title: "dashboard.avg_sleep".localized,
                value: "dashboard.avg_sleep_value".localized(with: viewModel.averageSleep),
                icon: "bed.double.fill",
                trend: compactSeries(viewModel.sleepPoints),
                color: ChartStyleGuide.SemanticColor.sleep
            )
            summaryCard(
                title: "dashboard.avg_mood".localized,
                value: "dashboard.avg_mood_value".localized(with: viewModel.averageMood),
                icon: "face.smiling.fill",
                trend: compactSeries(viewModel.moodPoints),
                color: ChartStyleGuide.SemanticColor.mood
            )
            summaryCard(
                title: "dashboard.meetings".localized,
                value: "\(viewModel.totalMeetings)",
                icon: "calendar.badge.clock",
                trend: compactSeries(viewModel.activityPoints),
                color: ChartStyleGuide.SemanticColor.meetings
            )
        }
    }

    private func summaryCard(
        title: String,
        value: String,
        icon: String,
        trend: [Double],
        color: Color
    ) -> some View {
        let trendDelta = trendPercentageChange(trend)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("TextSecondary"))

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: trendDelta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(Int(abs(trendDelta)).formatted())%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(trendDelta >= 0 ? ChartStyleGuide.SemanticColor.positive : ChartStyleGuide.SemanticColor.negative)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((trendDelta >= 0 ? ChartStyleGuide.SemanticColor.positive : ChartStyleGuide.SemanticColor.negative).opacity(0.12))
                .clipShape(Capsule())
            }

            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("TextPrimary"))

            if trend.count > 1 {
                SparklineView(data: trend, color: color, height: 42)
            }
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color("BackgroundLight"), color.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(color.opacity(0.22), lineWidth: 1)
        )
    }

    private var sleepChartSection: some View {
        let chartData = toSeries(viewModel.sleepPoints)
        return VStack(alignment: .leading, spacing: 8) {
            if chartData.isEmpty {
                ChartEmptyState(
                    title: "chart.collecting".localized,
                    message: "chart.collecting_detail".localized(with: 7, 0),
                    daysRequired: 7,
                    daysCollected: 0
                )
            } else {
                TrendLineChart(
                    title: "dashboard.sleep_trend".localized,
                    insight: "dashboard.avg_sleep_value".localized(with: viewModel.averageSleep),
                    data: chartData,
                    color: ChartStyleGuide.SemanticColor.sleep,
                    unit: "s",
                    period: selectedPeriod
                )
            }
        }
    }

    private var moodChartSection: some View {
        let chartData = toSeries(viewModel.moodPoints.filter { $0.value > 0 })
        return VStack(alignment: .leading, spacing: 8) {
            if chartData.isEmpty {
                ChartEmptyState(
                    title: "chart.collecting".localized,
                    message: "chart.collecting_detail".localized(with: 7, 0),
                    daysRequired: 7,
                    daysCollected: 0
                )
            } else {
                TrendLineChart(
                    title: "dashboard.mood_trend".localized,
                    insight: "dashboard.avg_mood_value".localized(with: viewModel.averageMood),
                    data: chartData,
                    color: ChartStyleGuide.SemanticColor.mood,
                    unit: "/5",
                    period: selectedPeriod
                )
            }
        }
    }

    private var activityChartSection: some View {
        let bars = viewModel.activityPoints.map { point in
            ComparisonBarChart.BarDataPoint(
                label: point.date.formatted(.dateTime.weekday(.abbreviated)),
                value: point.value,
                isHighlighted: point.value >= 3,
                comparisonValue: nil
            )
        }

        return ComparisonBarChart(
            title: "dashboard.activity_density".localized,
            insight: "dashboard.meeting_count_value".localized(with: viewModel.totalMeetings),
            data: bars,
            color: ChartStyleGuide.SemanticColor.meetings,
            unit: "adet"
        )
    }

    private func chartMax(for points: [DashboardViewModel.DataPoint]) -> Double {
        let finiteValues = points.map(\.value).filter { $0.isFinite && !$0.isNaN }
        return finiteValues.max() ?? 0
    }

    private func toSeries(_ points: [DashboardViewModel.DataPoint]) -> [TimeSeriesPoint] {
        let values = points.map(\.value).filter { $0 > 0 }
        let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)

        return points.map { point in
            let comparison: Double?
            if average > 0 {
                comparison = ((point.value - average) / average) * 100
            } else {
                comparison = nil
            }

            return TimeSeriesPoint(
                date: point.date,
                value: point.value,
                isEstimated: point.value == 0,
                comparisonToAverage: comparison
            )
        }
    }

    private func compactSeries(_ points: [DashboardViewModel.DataPoint]) -> [Double] {
        points.map(\.value).filter { $0.isFinite && !$0.isNaN }
    }

    private func trendPercentageChange(_ values: [Double]) -> Double {
        guard let first = values.first, let last = values.last, first > 0 else { return 0 }
        return ((last - first) / first) * 100
    }

    private func executiveChip(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(Color("TextPrimary"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.16))
            .clipShape(Capsule())
    }
}
