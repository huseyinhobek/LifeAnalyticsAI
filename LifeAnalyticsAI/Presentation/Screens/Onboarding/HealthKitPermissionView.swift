// MARK: - Presentation.Screens.Onboarding

import SwiftUI

struct HealthKitPermissionView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    @State private var isAuthorized = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundLight"), Color("PrimaryBlue").opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color("PrimaryBlue"))

                Text("onboarding.health.permission_title".localized)
                    .font(Theme.titleFont)
                    .foregroundStyle(Color("TextPrimary"))

                Text("onboarding.health.permission_body".localized)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Color("TextSecondary"))

                HStack(spacing: 10) {
                    Image(systemName: isAuthorized ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(isAuthorized ? Color("MoodExcellent") : Color("MoodBad"))
                    Text(isAuthorized ? "onboarding.status.granted".localized : "onboarding.status.waiting".localized)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Color("TextPrimary"))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.captionFont)
                        .foregroundStyle(Color("MoodBad"))
                }

                VStack(spacing: 12) {
                    Button {
                        Task { await requestHealthAccess() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("onboarding.health.permission_button".localized)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("PrimaryBlue"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                    .disabled(isLoading)

                    Button("onboarding.skip_now".localized) {
                        onSkip()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color("TextSecondary"))
                }

                Spacer(minLength: 0)
            }
            .padding(Theme.paddingLarge)
        }
        .onAppear {
            isAuthorized = dependencyContainer.healthKitService.isAuthorized()
        }
    }

    @MainActor
    private func requestHealthAccess() async {
        isLoading = true
        defer { isLoading = false }

        do {
            isAuthorized = try await dependencyContainer.healthKitService.requestAuthorization()
            try await dependencyContainer.healthKitService.setupBackgroundDelivery()
            _ = try await dependencyContainer.healthKitSyncManager.syncSleepData()
            errorMessage = nil
            onContinue()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
