// MARK: - Presentation.Screens.MoodEntry

import SwiftUI

struct MoodEntryView: View {
    @StateObject private var viewModel: MoodEntryViewModel
    @State private var highlightedMood: MoodLevel?
    @State private var feedbackTrigger = 0

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
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.58)) {
                                viewModel.selectedMoodLevel = mood
                                highlightedMood = mood
                            }
                            feedbackTrigger += 1

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    if highlightedMood == mood {
                                        highlightedMood = nil
                                    }
                                }
                            }
                        } label: {
                            Text(mood.emoji)
                                .font(.system(size: 30))
                                .frame(width: 56, height: 56)
                                .scaleEffect(highlightedMood == mood ? 1.2 : (viewModel.selectedMoodLevel == mood ? 1.08 : 1.0))
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
        .background(
            LinearGradient(
                colors: [
                    Color("BackgroundLight"),
                    (viewModel.selectedMoodLevel.map { Theme.moodColor($0.rawValue).opacity(0.18) } ?? Color("PrimaryBlue").opacity(0.08))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.25), value: viewModel.selectedMoodLevel)
        )
        .navigationTitle("Mood Girisi")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact, trigger: feedbackTrigger)
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
