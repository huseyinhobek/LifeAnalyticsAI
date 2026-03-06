// MARK: - Presentation.Screens.MoodEntry

import SwiftUI

struct MoodEntryView: View {
    @StateObject private var viewModel: MoodEntryViewModel

    init(viewModel: MoodEntryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Bugun nasil hissediyorsun?")
                    .font(Theme.titleFont)
                    .foregroundStyle(Color("TextPrimary"))

                HStack(spacing: 12) {
                    ForEach(MoodLevel.allCases, id: \.rawValue) { mood in
                        Button {
                            viewModel.selectedMoodLevel = mood
                        } label: {
                            Text(mood.emoji)
                                .font(.system(size: 30))
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(viewModel.selectedMoodLevel == mood ? Theme.moodColor(mood.rawValue).opacity(0.2) : Color("BackgroundLight"))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.selectedMoodLevel == mood ? Theme.moodColor(mood.rawValue) : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Aktiviteler")
                    .font(Theme.headlineFont)
                    .foregroundStyle(Color("TextPrimary"))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                    ForEach(ActivityTag.allCases, id: \.rawValue) { tag in
                        let isSelected = viewModel.selectedActivities.contains(tag)

                        Button {
                            viewModel.toggleActivity(tag)
                        } label: {
                            Text(tag.displayName)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? Color("PrimaryBlue") : Color("BackgroundLight"))
                                .foregroundStyle(isSelected ? Color.white : Color("TextPrimary"))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Not (opsiyonel)")
                    .font(Theme.headlineFont)
                    .foregroundStyle(Color("TextPrimary"))

                TextEditor(text: $viewModel.note)
                    .frame(minHeight: 110)
                    .padding(8)
                    .background(Color("BackgroundLight"))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Theme.captionFont)
                        .foregroundStyle(Color("MoodBad"))
                }

                if viewModel.didSave {
                    Text("Mood kaydedildi")
                        .font(Theme.captionFont)
                        .foregroundStyle(Color("MoodExcellent"))
                }

                Button {
                    Task { await viewModel.saveEntry() }
                } label: {
                    HStack {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        }

                        Text("Kaydet")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("PrimaryBlue"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .disabled(viewModel.isSaving)
            }
            .padding(Theme.paddingLarge)
        }
        .background(Color("BackgroundLight").opacity(0.4))
        .navigationTitle("Mood Girisi")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ActivityTag {
    var displayName: String {
        switch self {
        case .exercise:
            return "Egzersiz"
        case .work:
            return "Is"
        case .social:
            return "Sosyal"
        case .reading:
            return "Okuma"
        case .meditation:
            return "Meditasyon"
        case .nature:
            return "Doga"
        case .family:
            return "Aile"
        case .travel:
            return "Seyahat"
        }
    }
}
