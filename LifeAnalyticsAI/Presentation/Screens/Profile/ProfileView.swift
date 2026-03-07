// MARK: - Presentation.Screens.Profile

import Charts
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                summaryHeader
                statsGrid
                confidenceSection

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.load() }
                    }
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
        .navigationTitle("profile.nav_title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("profile.data_profile".localized, systemImage: "person.crop.circle.badge.checkmark")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("profile.collection_start".localized(with: viewModel.dataCollectionStartDate.formatted(date: .abbreviated, time: .omitted)))
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextSecondary"))
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var statsGrid: some View {
        let columns: [GridItem] = horizontalSizeClass == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: Theme.paddingMedium) {
            profileCard(
                title: "profile.total_days".localized,
                value: "\(viewModel.totalTrackedDays)",
                icon: "calendar.badge.clock"
            )
            profileCard(
                title: "profile.avg_confidence".localized,
                value: "%\(Int((viewModel.averageConfidence * 100).rounded()))",
                icon: "checkmark.seal"
            )
        }
    }

    private func profileCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("TextPrimary"))
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("profile.confidence_trend".localized, systemImage: "chart.line.uptrend.xyaxis")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            if viewModel.confidenceTrend.isEmpty {
                EmptyStateView(
                    title: "profile.empty_confidence_title".localized,
                    subtitle: "profile.empty_confidence_subtitle".localized,
                    icon: "chart.line.flattrend.xyaxis"
                )
            } else {
                Chart(viewModel.confidenceTrend) { point in
                    LineMark(
                        x: .value("Tarih", point.date),
                        y: .value("Skor", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color("PrimaryBlue"))

                    AreaMark(
                        x: .value("Tarih", point.date),
                        y: .value("Skor", point.score)
                    )
                    .foregroundStyle(Color("PrimaryBlue").opacity(0.15))
                }
                .chartYScale(domain: 0...1)
                .frame(height: horizontalSizeClass == .regular ? 280 : 210)
                .padding(12)
                .background(Color("BackgroundLight"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
        }
    }
}
