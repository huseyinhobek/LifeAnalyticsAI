// MARK: - Presentation.ViewModels

import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    struct ConfidencePoint: Identifiable {
        let date: Date
        let score: Double

        var id: Date { date }
    }

    @Published private(set) var dataCollectionStartDate: Date
    @Published private(set) var totalTrackedDays: Int = 0
    @Published private(set) var confidenceTrend: [ConfidencePoint] = []
    @Published private(set) var averageConfidence: Double = 0
    @Published var errorMessage: String?

    private let userDefaultsManager: UserDefaultsManager
    private let insightRepository: InsightRepositoryProtocol

    init(userDefaultsManager: UserDefaultsManager, insightRepository: InsightRepositoryProtocol) {
        self.userDefaultsManager = userDefaultsManager
        self.insightRepository = insightRepository
        self.dataCollectionStartDate = userDefaultsManager.dataCollectionStartDate ?? Date().startOfDay
    }

    func load() async {
        do {
            let insights = try await insightRepository.fetchInsights(limit: 180)
            let ordered = insights.sorted { $0.date < $1.date }

            if let start = userDefaultsManager.dataCollectionStartDate {
                dataCollectionStartDate = start.startOfDay
            } else if let earliest = ordered.first?.date.startOfDay {
                dataCollectionStartDate = earliest
                userDefaultsManager.dataCollectionStartDate = earliest
            } else {
                let fallback = Date().startOfDay
                dataCollectionStartDate = fallback
                userDefaultsManager.dataCollectionStartDate = fallback
            }

            let elapsedDays = Calendar.current.dateComponents([.day], from: dataCollectionStartDate, to: Date().startOfDay).day ?? 0
            totalTrackedDays = max(1, elapsedDays + 1)

            confidenceTrend = ordered.map {
                ConfidencePoint(date: $0.date, score: score(for: $0.confidenceLevel))
            }

            if confidenceTrend.isEmpty {
                averageConfidence = 0
            } else {
                averageConfidence = confidenceTrend.map(\.score).reduce(0, +) / Double(confidenceTrend.count)
            }

            errorMessage = nil
        } catch {
            confidenceTrend = []
            averageConfidence = 0
            errorMessage = error.localizedDescription
        }
    }

    private func score(for level: Insight.ConfidenceLevel) -> Double {
        switch level {
        case .low:
            return 0.35
        case .medium:
            return 0.65
        case .high:
            return 0.9
        }
    }
}
