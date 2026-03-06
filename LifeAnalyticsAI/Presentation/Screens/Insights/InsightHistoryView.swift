// MARK: - Presentation.Screens.Insights

import SwiftUI

struct InsightHistoryView: View {
    @StateObject private var viewModel: InsightHistoryViewModel
    @Bindable var router: NavigationRouter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(viewModel: InsightHistoryViewModel, router: NavigationRouter) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                headerCard
                filterSection

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Theme.captionFont)
                        .foregroundStyle(Color("MoodBad"))
                }

                if viewModel.isLoading && viewModel.insights.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.paddingLarge)
                } else if viewModel.filteredInsights.isEmpty {
                    emptyState
                } else {
                    insightsGrid
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
        .navigationTitle("Insight Gecmisi")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Insight ara")
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tum Icgoruler", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("Kronolojik sirayla \(viewModel.filteredInsights.count) kayit")
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextSecondary"))
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Filtrele")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "Tum Tipler", icon: "line.3.horizontal.decrease.circle", isSelected: viewModel.selectedType == nil) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.selectedType = nil
                        }
                    }

                    ForEach(InsightHistoryViewModel.supportedTypes, id: \.self) { type in
                        filterChip(title: type.displayName, icon: type.iconName, isSelected: viewModel.selectedType == type) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.selectedType = type
                            }
                        }
                    }
                }
            }
        }
    }

    private var insightsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: Theme.paddingMedium) {
            ForEach(viewModel.filteredInsights) { insight in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        router.navigate(to: .insightDetail(insight))
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Label(insight.type.displayName, systemImage: insight.type.iconName)
                                .font(Theme.captionFont)
                                .foregroundStyle(Color("SecondaryBlue"))

                            Spacer()

                            Text(insight.confidenceLevel.label)
                                .font(Theme.captionFont)
                                .foregroundStyle(Color("TextSecondary"))
                        }

                        Text(insight.title)
                            .font(.headline)
                            .foregroundStyle(Color("TextPrimary"))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(insight.body)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Color("TextSecondary"))
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(insight.date.formatted(date: .abbreviated, time: .shortened))
                            .font(Theme.captionFont)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                    .padding(Theme.paddingMedium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("BackgroundLight"))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color("TextSecondary"))

            Text("Filtreye uygun insight bulunamadi")
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))

            if viewModel.hasActiveFilters {
                Button("Filtreleri Temizle") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        viewModel.clearFilters()
                    }
                }
                .font(Theme.captionFont)
                .foregroundStyle(Color("SecondaryBlue"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.paddingLarge)
        .padding(.horizontal, Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var gridColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
        return [GridItem(.flexible())]
    }

    private func filterChip(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(Theme.captionFont)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.white : Color("TextPrimary"))
            .background(isSelected ? Color("PrimaryBlue") : Color("BackgroundLight"))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Color("PrimaryBlue").opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

private extension Insight.InsightType {
    var displayName: String {
        switch self {
        case .correlation:
            return "Korelasyon"
        case .anomaly:
            return "Anomali"
        case .prediction:
            return "Tahmin"
        case .trend:
            return "Trend"
        case .seasonal:
            return "Mevsimsel"
        }
    }

    var iconName: String {
        switch self {
        case .correlation:
            return "link"
        case .anomaly:
            return "exclamationmark.triangle"
        case .prediction:
            return "sparkles"
        case .trend:
            return "chart.line.uptrend.xyaxis"
        case .seasonal:
            return "calendar"
        }
    }
}
