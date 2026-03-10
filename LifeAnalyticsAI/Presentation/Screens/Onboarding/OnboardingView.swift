// MARK: - Presentation.Screens.Onboarding

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var currentStep: Step = .welcome
    @State private var healthAuthorized = false
    @State private var calendarAuthorized = false
    @State private var selectedMood: MoodLevel?
    @State private var moodNote = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    let onComplete: () -> Void

    private enum Step: Int, CaseIterable {
        case welcome
        case healthKit
        case calendar
        case firstMood

        var title: String {
            switch self {
            case .welcome:
                return "onboarding.step.welcome".localized
            case .healthKit:
                return "onboarding.step.healthkit".localized
            case .calendar:
                return "onboarding.step.calendar".localized
            case .firstMood:
                return "onboarding.step.first_mood".localized
            }
        }
    }

    private enum Field: Hashable {
        case moodNote
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundLight"), Color("PrimaryBlue").opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: Theme.paddingMedium) {
                    progressHeader

                    Group {
                        switch currentStep {
                        case .welcome:
                            welcomeStep
                        case .healthKit:
                            healthStep
                        case .calendar:
                            calendarStep
                        case .firstMood:
                            firstMoodStep
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .frame(maxWidth: contentWidth(for: geometry.size.width))

                    Spacer(minLength: 0)
                }
                .padding(Theme.paddingLarge)
            }
        }
        .task {
            healthAuthorized = dependencyContainer.healthKitService.isAuthorized()
        }
        .keyboardDismissOnTap()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("general.done".localized) {
                    focusedField = nil
                }
            }
        }
        .onChange(of: currentStep) {
            focusedField = nil
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("onboarding.title".localized)
                .font(Theme.titleFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("onboarding.step_progress".localized(with: currentStep.rawValue + 1, Step.allCases.count, currentStep.title))
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 6) {
                ForEach(Step.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step.rawValue <= currentStep.rawValue ? Color("PrimaryBlue") : Color("TextSecondary").opacity(0.2))
                        .frame(height: 6)
                }
            }
        }
    }

    private var welcomeStep: some View {
        stepCard(icon: "sparkles", title: "onboarding.welcome.card_title".localized, subtitle: "onboarding.welcome.card_subtitle".localized) {
            VStack(alignment: .leading, spacing: 10) {
                bullet("onboarding.welcome.bullet1".localized)
                bullet("onboarding.welcome.bullet2".localized)
                bullet("onboarding.welcome.bullet3".localized)
            }

            Button("onboarding.start".localized) {
                goTo(.healthKit)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryBlue"))
            .font(Theme.captionFont)
        }
    }

    private var healthStep: some View {
        stepCard(icon: "heart.text.square.fill", title: "onboarding.health.title".localized, subtitle: "onboarding.health.subtitle".localized) {
            statusRow(isDone: healthAuthorized, okText: "onboarding.status.granted".localized, waitingText: "onboarding.status.waiting".localized)

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("MoodBad"))
            }

            Button {
                Task { await requestHealthKit() }
            } label: {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("onboarding.health.grant".localized)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryBlue"))
            .font(Theme.captionFont)
            .disabled(isLoading)

            footerButtons(back: .welcome, next: .calendar)
        }
    }

    private var calendarStep: some View {
        stepCard(icon: "calendar.badge.clock", title: "onboarding.calendar.title".localized, subtitle: "onboarding.calendar.subtitle".localized) {
            statusRow(isDone: calendarAuthorized, okText: "onboarding.status.granted".localized, waitingText: "onboarding.status.waiting".localized)

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("MoodBad"))
            }

            Button {
                Task { await requestCalendar() }
            } label: {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("onboarding.calendar.grant".localized)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryBlue"))
            .font(Theme.captionFont)
            .disabled(isLoading)

            footerButtons(back: .healthKit, next: .firstMood)
        }
    }

    private var firstMoodStep: some View {
        stepCard(icon: "face.smiling", title: "onboarding.first_mood.title".localized, subtitle: "onboarding.first_mood.subtitle".localized) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(MoodLevel.allCases, id: \.self) { level in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            selectedMood = level
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(level.emoji)
                                .font(.system(size: 26))
                            Text(level.label)
                                .font(Theme.captionFont)
                                .foregroundStyle(Color("TextPrimary"))
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(selectedMood == level ? Color("PrimaryBlue").opacity(0.15) : Color("BackgroundLight"))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                .stroke(selectedMood == level ? Color("PrimaryBlue") : Color("TextSecondary").opacity(0.25), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("onboarding.note_placeholder".localized, text: $moodNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .focused($focusedField, equals: .moodNote)
                .onSubmit {
                    focusedField = nil
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("MoodBad"))
            }

            Button {
                Task { await saveFirstMood() }
            } label: {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("onboarding.complete".localized)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryBlue"))
            .font(Theme.captionFont)
            .disabled(selectedMood == nil || isLoading)

            Button("onboarding.back".localized) {
                goTo(.calendar)
            }
            .font(Theme.captionFont)
            .foregroundStyle(Color("TextSecondary"))
        }
    }

    private func footerButtons(back: Step, next: Step) -> some View {
        HStack {
            Button("onboarding.back".localized) {
                goTo(back)
            }
            .font(Theme.captionFont)
            .foregroundStyle(Color("TextSecondary"))

            Spacer()

            Button("onboarding.skip".localized) {
                goTo(next)
            }
            .font(Theme.captionFont)
            .foregroundStyle(Color("SecondaryBlue"))
        }
    }

    private func stepCard<Content: View>(icon: String, title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Image(systemName: icon)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color("PrimaryBlue"))

            Text(title)
                .font(Theme.titleFont)
                .foregroundStyle(Color("TextPrimary"))

            Text(subtitle)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextSecondary"))

            content()
        }
        .padding(Theme.paddingLarge)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private func statusRow(isDone: Bool, okText: String, waitingText: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "clock")
                .foregroundStyle(isDone ? Color("MoodExcellent") : Color("TextSecondary"))
            Text(isDone ? okText : waitingText)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))
        }
    }

    private func bullet(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle")
            .font(Theme.bodyFont)
            .foregroundStyle(Color("TextPrimary"))
    }

    private func contentWidth(for width: CGFloat) -> CGFloat {
        if horizontalSizeClass == .regular {
            return min(width * 0.68, 760)
        }
        return width
    }

    private func goTo(_ step: Step) {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            currentStep = step
            errorMessage = nil
        }
    }

    @MainActor
    private func requestHealthKit() async {
        isLoading = true
        defer { isLoading = false }

        do {
            healthAuthorized = try await dependencyContainer.healthKitService.requestAuthorization()
            try await dependencyContainer.healthKitService.setupBackgroundDelivery()
            _ = try await dependencyContainer.healthKitSyncManager.syncSleepData()
            errorMessage = nil
            goTo(.calendar)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func requestCalendar() async {
        isLoading = true
        defer { isLoading = false }

        do {
            calendarAuthorized = try await dependencyContainer.calendarService.requestAccess()
            _ = try await dependencyContainer.calendarSyncManager.syncEvents()
            errorMessage = nil
            goTo(.firstMood)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func saveFirstMood() async {
        focusedField = nil

        guard let selectedMood else {
            errorMessage = "onboarding.select_mood_error".localized
            return
        }

        isLoading = true
        defer { isLoading = false }

        let note = moodNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = MoodEntry(
            id: UUID(),
            date: Date().startOfDay,
            timestamp: Date(),
            value: selectedMood.rawValue,
            note: note.isEmpty ? nil : note,
            activities: []
        )

        do {
            try await dependencyContainer.saveMoodEntryUseCase.execute(entry)
            errorMessage = nil
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
