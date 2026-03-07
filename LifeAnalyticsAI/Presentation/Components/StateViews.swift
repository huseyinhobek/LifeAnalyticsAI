// MARK: - Presentation.Components.StateViews

import SwiftUI

struct LoadingStateView: View {
    let title: String
    let subtitle: String?
    var icon: String = "hourglass"

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color("PrimaryBlue"))
                .accessibilityHidden(true)

            ProgressView()
                .tint(Color("PrimaryBlue"))

            Text(title)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.paddingLarge)
        .padding(.horizontal, Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle ?? "general.loading".localized)
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String?
    var icon: String = "tray"
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color("TextSecondary"))
                .accessibilityHidden(true)

            Text(title)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Theme.captionFont)
                    .buttonStyle(.bordered)
                    .tint(Color("SecondaryBlue"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.paddingLarge)
        .padding(.horizontal, Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .contain)
    }
}

struct ErrorStateView: View {
    let message: String
    var retryTitle: String = "error.retry".localized
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color("MoodBad"))
                .accessibilityHidden(true)

            Text(message)
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextPrimary"))
                .multilineTextAlignment(.center)

            if let retryAction {
                Button(retryTitle, action: retryAction)
                    .font(Theme.captionFont)
                    .buttonStyle(.bordered)
                    .tint(Color("MoodBad"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.paddingLarge)
        .padding(.horizontal, Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .contain)
    }
}
