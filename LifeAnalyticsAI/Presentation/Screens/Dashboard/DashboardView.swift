// MARK: - Presentation.Screens.Dashboard

import Charts
import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @Bindable var router: NavigationRouter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedSleepDate: Date?
    @State private var selectedMoodDate: Date?
    @State private var selectedActivityDate: Date?

    init(viewModel: DashboardViewModel, router: NavigationRouter) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                headerCard
                windowPicker
                summaryCards

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                }

                if viewModel.isLoading && viewModel.sleepPoints.isEmpty {
                    LoadingStateView(
                        title: "Istatistikler yukleniyor",
                        subtitle: "Uyku, mood ve aktivite verileri hazirlaniyor",
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
        .navigationTitle("Istatistik Panosu")
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Kisisel Performans", systemImage: "chart.xyaxis.line")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("Uyku, mood ve aktivite trendleri tek ekranda")
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextSecondary"))

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    router.navigate(to: .weeklyReport(weekStart: Date().startOfWeek))
                }
            } label: {
                Label("Haftalik AI Raporu", systemImage: "doc.text.image")
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("SecondaryBlue"))
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var windowPicker: some View {
        HStack(spacing: 8) {
            ForEach(DashboardViewModel.TimeWindow.allCases, id: \.self) { window in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        viewModel.selectedWindow = window
                    }
                    Task { await viewModel.refresh() }
                } label: {
                    Text(window.title)
                        .font(Theme.captionFont)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(viewModel.selectedWindow == window ? Color.white : Color("TextPrimary"))
                        .background(viewModel.selectedWindow == window ? Color("PrimaryBlue") : Color("BackgroundLight"))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var summaryCards: some View {
        let columns: [GridItem] = horizontalSizeClass == .regular
            ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: Theme.paddingMedium) {
            summaryCard(
                title: "Ortalama Uyku",
                value: String(format: "%.1f saat", viewModel.averageSleep),
                icon: "bed.double.fill"
            )
            summaryCard(
                title: "Ortalama Mood",
                value: String(format: "%.1f / 5", viewModel.averageMood),
                icon: "face.smiling.fill"
            )
            summaryCard(
                title: "Toplanti",
                value: "\(viewModel.totalMeetings)",
                icon: "calendar.badge.clock"
            )
        }
    }

    private func summaryCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("TextPrimary"))
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var sleepChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Uyku Trendi", systemImage: "moon.stars.fill")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Chart(viewModel.sleepPoints) { point in
                LineMark(
                    x: .value("Tarih", point.date),
                    y: .value("Saat", point.value)
                )
                .foregroundStyle(Color("PrimaryBlue"))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Tarih", point.date),
                    y: .value("Saat", point.value)
                )
                .foregroundStyle(Color("PrimaryBlue").opacity(0.12))

                if selectedSleepDate?.startOfDay == point.date.startOfDay {
                    PointMark(
                        x: .value("Tarih", point.date),
                        y: .value("Saat", point.value)
                    )
                    .foregroundStyle(Color("PrimaryBlue"))
                    .annotation(position: .top) {
                        Text(String(format: "%.1f saat", point.value))
                            .font(Theme.captionFont)
                            .padding(6)
                            .background(Color("BackgroundLight"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .chartYScale(domain: 0...max(9, chartMax(for: viewModel.sleepPoints)))
            .chartXSelection(value: $selectedSleepDate)
            .frame(height: 220)
            .padding(12)
            .background(Color("BackgroundLight"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private var moodChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Mood Trendi", systemImage: "face.smiling")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Chart(viewModel.moodPoints.filter { $0.value > 0 }) { point in
                LineMark(
                    x: .value("Tarih", point.date),
                    y: .value("Mood", point.value)
                )
                .foregroundStyle(Color("MoodGood"))
                .interpolationMethod(.catmullRom)

                if selectedMoodDate?.startOfDay == point.date.startOfDay {
                    RuleMark(x: .value("Secim", point.date))
                        .foregroundStyle(Color("TextSecondary").opacity(0.45))

                    PointMark(
                        x: .value("Tarih", point.date),
                        y: .value("Mood", point.value)
                    )
                    .foregroundStyle(Color("MoodGood"))
                    .annotation(position: .top) {
                        Text(String(format: "%.1f", point.value))
                            .font(Theme.captionFont)
                            .padding(6)
                            .background(Color("BackgroundLight"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .chartYScale(domain: 1...5)
            .chartXSelection(value: $selectedMoodDate)
            .frame(height: 210)
            .padding(12)
            .background(Color("BackgroundLight"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private var activityChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Aktivite Yogunlugu", systemImage: "calendar")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Chart(viewModel.activityPoints) { point in
                BarMark(
                    x: .value("Tarih", point.date),
                    y: .value("Toplanti", point.value)
                )
                .foregroundStyle(selectedActivityDate?.startOfDay == point.date.startOfDay ? Color("PrimaryBlue") : Color("SecondaryBlue"))
                .cornerRadius(5)

                if selectedActivityDate?.startOfDay == point.date.startOfDay {
                    RuleMark(x: .value("Secim", point.date))
                        .foregroundStyle(Color("TextSecondary").opacity(0.45))
                        .annotation(position: .top) {
                            Text("\(Int(point.value)) toplanti")
                                .font(Theme.captionFont)
                                .padding(6)
                                .background(Color("BackgroundLight"))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                }
            }
            .chartYScale(domain: 0...max(6, chartMax(for: viewModel.activityPoints) + 1))
            .chartXSelection(value: $selectedActivityDate)
            .frame(height: 210)
            .padding(12)
            .background(Color("BackgroundLight"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private func chartMax(for points: [DashboardViewModel.DataPoint]) -> Double {
        let finiteValues = points.map(\.value).filter { $0.isFinite && !$0.isNaN }
        return finiteValues.max() ?? 0
    }
}
