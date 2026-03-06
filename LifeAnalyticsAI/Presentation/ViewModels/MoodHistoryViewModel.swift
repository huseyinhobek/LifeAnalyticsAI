// MARK: - Presentation.ViewModels

import Combine
import Foundation

struct MoodTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MoodDistributionPoint: Identifiable {
    let id = UUID()
    let value: Int
    let label: String
    let count: Int
}

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

    var trendPoints: [MoodTrendPoint] {
        entries
            .sorted { $0.date < $1.date }
            .map { MoodTrendPoint(date: $0.date, value: Double($0.value)) }
    }

    var distributionPoints: [MoodDistributionPoint] {
        MoodLevel.allCases.map { level in
            let count = entries.filter { $0.value == level.rawValue }.count
            return MoodDistributionPoint(value: level.rawValue, label: level.emoji, count: count)
        }
    }

    func exportCSVToTemporaryFile() throws -> URL {
        let formatter = ISO8601DateFormatter()
        let lines = [csvHeader] + entries.map { entry in
            let note = csvEscaped(entry.note ?? "")
            let activities = csvEscaped(entry.activities.map { $0.displayName }.joined(separator: ", "))
            return [
                entry.id.uuidString,
                formatter.string(from: entry.date),
                formatter.string(from: entry.timestamp),
                String(entry.value),
                csvEscaped(entry.moodLevel.label),
                activities,
                note
            ].joined(separator: ",")
        }

        let csv = lines.joined(separator: "\n")
        let filename = "mood-history-\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private var csvHeader: String {
        "id,date,timestamp,moodValue,moodLabel,activities,note"
    }

    private func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
