// MARK: - Presentation.ViewModels

import Combine
import Foundation

@MainActor
final class MoodHistoryViewModel: ObservableObject {
    @Published private(set) var entries: [MoodEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let fetchMoodEntriesUseCase: FetchMoodEntriesUseCaseProtocol

    init(fetchMoodEntriesUseCase: FetchMoodEntriesUseCaseProtocol) {
        self.fetchMoodEntriesUseCase = fetchMoodEntriesUseCase
    }

    func loadLastYear() async {
        isLoading = true
        defer { isLoading = false }

        let to = Date()
        let from = Calendar.current.date(byAdding: .day, value: -365, to: to) ?? to

        do {
            entries = try await fetchMoodEntriesUseCase.execute(from: from, to: to)
            errorMessage = nil
        } catch {
            entries = []
            errorMessage = error.localizedDescription
        }
    }

    func moodEntry(for date: Date) -> MoodEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}
