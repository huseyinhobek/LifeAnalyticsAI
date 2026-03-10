// MARK: - Presentation.Screens.MoodEntry

import SwiftUI

struct MoodEntryView: View {
    @StateObject private var viewModel: MoodEntryViewModel
    @Bindable var router: NavigationRouter
    @Environment(\.dismiss) private var dismiss
    @State private var highlightedMood: MoodLevel?
    @State private var feedbackTrigger = 0
    @State private var showSavedToast = false
    @FocusState private var isNoteFocused: Bool

    init(viewModel: MoodEntryViewModel, router: NavigationRouter) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("mood.entry.how_feeling".localized)
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

                Text("mood.entry.activities".localized)
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

                Text("mood.entry.note_optional".localized)
                    .font(Theme.headlineFont)
                    .foregroundStyle(Color("TextPrimary"))

                TextEditor(text: $viewModel.note)
                    .frame(minHeight: 110)
                    .padding(8)
                    .background(Color("BackgroundLight"))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .focused($isNoteFocused)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Theme.captionFont)
                        .foregroundStyle(Color("MoodBad"))
                }

                if viewModel.didSave {
                    Text("mood.entry.saved".localized)
                        .font(Theme.captionFont)
                        .foregroundStyle(Color("MoodExcellent"))
                }

                Text("mood.entry.usage_hint".localized)
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("TextSecondary"))

                Button {
                    Task { await viewModel.saveEntry() }
                } label: {
                    HStack {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        }

                        Text("mood.entry.save".localized)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("PrimaryBlue"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .disabled(viewModel.isSaving)

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        router.navigate(to: .moodHistory)
                    }
                } label: {
                    Label("mood.entry.history".localized, systemImage: "clock.arrow.circlepath")
                        .font(Theme.bodyFont.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(Color("TextPrimary"))
                        .background(Color("BackgroundLight"))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                .stroke(Color("PrimaryBlue").opacity(0.25), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.paddingLarge)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDismissOnTap()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("general.done".localized) {
                    isNoteFocused = false
                }
            }
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
        .navigationTitle("mood.entry.nav_title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact, trigger: feedbackTrigger)
        .overlay(alignment: .bottom) {
            if showSavedToast {
                Text("mood.entry.saved_toast".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color("PrimaryBlue"))
                    .clipShape(Capsule())
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.didSave) { _, didSave in
            guard didSave else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                showSavedToast = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showSavedToast = false
                }
                dismiss()
            }
        }
    }
}
