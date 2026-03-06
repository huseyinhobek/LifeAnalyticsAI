// MARK: - Presentation.ViewModels

import Foundation

@MainActor
final class InsightHistoryViewModel: ObservableObject {
    static let supportedTypes: [Insight.InsightType] = [.trend, .correlation, .anomaly, .prediction, .seasonal]

    @Published private(set) var insights: [Insight] = []
    @Published private(set) var isLoading = false
    @Published var selectedType: Insight.InsightType?
    @Published var searchText = ""
    @Published var errorMessage: String?

    private let repository: InsightRepositoryProtocol

    init(repository: InsightRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        if isLoading { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            insights = try await repository.fetchInsights(limit: 200)
            errorMessage = nil
        } catch {
            insights = []
            errorMessage = error.localizedDescription
        }
    }

    var filteredInsights: [Insight] {
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return insights
            .filter { insight in
                if let selectedType, insight.type != selectedType {
                    return false
                }

                guard !query.isEmpty else {
                    return true
                }
                return insight.title.lowercased().contains(query) || insight.body.lowercased().contains(query)
            }
            .sorted { $0.date > $1.date }
    }

    var hasActiveFilters: Bool {
        selectedType != nil || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func clearFilters() {
        selectedType = nil
        searchText = ""
    }
}
