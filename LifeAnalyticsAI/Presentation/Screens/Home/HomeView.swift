// MARK: - Presentation.Screens.Home

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Bindable var router: NavigationRouter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(viewModel: HomeViewModel, router: NavigationRouter) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                headerCard
                moodCTA
                sleepSummaryCard
                quickStatsGrid

                if let summary = viewModel.weeklyReportSummary, !summary.isEmpty {
                    weeklySummaryCard(summary)
                }

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                }
            }
            .padding(Theme.paddingLarge)
        }
        .background(
            LinearGradient(
                colors: [Color("BackgroundLight"), Color("SecondaryBlue").opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Ana Sayfa")
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Bugunun Icgorusu", systemImage: "sparkles.rectangle.stack")
                    .font(Theme.headlineFont)
                    .foregroundStyle(Color("TextPrimary"))
                Spacer()
                if viewModel.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Text(viewModel.todayInsightText)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color("PrimaryBlue").opacity(0.18), Color("BackgroundLight")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var moodCTA: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                router.navigate(to: .moodEntry(preset: nil))
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "face.smiling")
                Text("Mood Check-in Yap")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, Theme.paddingMedium)
            .foregroundStyle(.white)
            .background(Color("PrimaryBlue"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var sleepSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Uyku Ozeti", systemImage: "bed.double.fill")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text(String(format: "Son 7 gun ortalamasi %.1f saat", viewModel.averageSleepHours))
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var quickStatsGrid: some View {
        let twoColumns = [GridItem(.flexible()), GridItem(.flexible())]
        let singleColumn = [GridItem(.flexible())]

        return LazyVGrid(columns: horizontalSizeClass == .regular ? twoColumns : singleColumn, spacing: Theme.paddingMedium) {
            quickStatCard(
                title: "Ortalama Mood",
                value: String(format: "%.1f / 5", viewModel.averageMood),
                icon: "face.smiling.inverse"
            )

            quickStatCard(
                title: "Bugunku Toplanti",
                value: "\(viewModel.todayMeetingCount)",
                icon: "calendar"
            )
        }
    }

    private func quickStatCard(title: String, value: String, icon: String) -> some View {
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

    private func weeklySummaryCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Haftalik Ozet", systemImage: "doc.text.magnifyingglass")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text(WeeklyReportTextFormatter.previewText(summary))
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))
                .lineLimit(4)

            Button("Tum raporu gor") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    router.navigate(to: .weeklyReport(weekStart: Date().startOfWeek))
                }
            }
            .font(Theme.captionFont)
            .foregroundStyle(Color("SecondaryBlue"))
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

}
