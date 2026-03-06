// MARK: - Presentation.ViewModels

import Combine
import Foundation

@MainActor
final class MoodEntryViewModel: ObservableObject {
    @Published var selectedMoodLevel: MoodLevel?
    @Published var note = ""
    @Published var selectedActivities = Set<ActivityTag>()
    @Published private(set) var isSaving = false
    @Published private(set) var didSave = false
    @Published var errorMessage: String?

    private let saveMoodEntryUseCase: SaveMoodEntryUseCaseProtocol

    init(saveMoodEntryUseCase: SaveMoodEntryUseCaseProtocol) {
        self.saveMoodEntryUseCase = saveMoodEntryUseCase
    }

    func toggleActivity(_ activity: ActivityTag) {
        if selectedActivities.contains(activity) {
            selectedActivities.remove(activity)
        } else {
            selectedActivities.insert(activity)
        }
    }

    func applyPresetMood(value: Int?) {
        guard let value, let mood = MoodLevel(rawValue: value) else { return }
        selectedMoodLevel = mood
        didSave = false
        errorMessage = nil
    }

    func saveEntry() async {
        guard let selectedMoodLevel else {
            errorMessage = "Lutfen bir mood seciniz."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = MoodEntry(
            id: UUID(),
            date: Date().startOfDay,
            timestamp: Date(),
            value: selectedMoodLevel.rawValue,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            activities: selectedActivities.sorted { $0.rawValue < $1.rawValue }
        )

        do {
            try await saveMoodEntryUseCase.execute(entry)
            didSave = true
            errorMessage = nil
        } catch {
            didSave = false
            errorMessage = error.localizedDescription
        }
    }

    func resetForm() {
        selectedMoodLevel = nil
        note = ""
        selectedActivities.removeAll()
        didSave = false
        errorMessage = nil
    }
}
