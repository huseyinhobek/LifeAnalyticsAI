// MARK: - Presentation.Screens.Settings

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    var router: NavigationRouter?
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var shareURL: URL?
    @State private var isShareSheetPresented = false
    @State private var showLanguagePicker = false

    init(viewModel: SettingsViewModel, router: NavigationRouter? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Theme.paddingMedium) {
                languageCard
                notificationCard
                securityCard
                dataSourceCard
                personalizationCard
                exportCard
                accountCard
            }
            .padding(Theme.paddingLarge)
        }
        .background(
            LinearGradient(
                colors: [Color("BackgroundLight"), Color("SecondaryBlue").opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDismissOnTap()
        .alert("settings.info".localized, isPresented: statusAlertBinding) {
            Button("general.done".localized, role: .cancel) {
                viewModel.statusMessage = nil
            }
        } message: {
            Text(viewModel.statusMessage ?? "")
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguageSelectionView()
        }
 #if canImport(UIKit)
        .sheet(isPresented: $isShareSheetPresented, onDismiss: {
            shareURL = nil
        }) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
 #endif
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                showLanguagePicker = true
            } label: {
                HStack {
                    Label {
                        Text("settings.language".localized)
                    } icon: {
                        Image(systemName: "globe")
                    }
                    Spacer()
                    Text(languageManager.currentLanguage.flag + " " + languageManager.currentLanguage.displayName)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("settings.security".localized, systemImage: "lock.shield")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Toggle("settings.app_lock".localized, isOn: $viewModel.appLockEnabled)
                .tint(Color("PrimaryBlue"))

            Text("settings.proxy_security_info".localized)
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            Button("settings.run_security_audit".localized) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    viewModel.runSecurityAuditChecklist()
                }
            }
            .font(Theme.captionFont)
            .buttonStyle(.borderedProminent)
            .tint(Color("SecondaryBlue"))

            if !viewModel.securityAuditResults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.securityAuditResults) { check in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: iconName(for: check.status))
                                .foregroundStyle(iconColor(for: check.status))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(check.title)
                                    .font(Theme.captionFont.weight(.semibold))
                                    .foregroundStyle(Color("TextPrimary"))
                                Text(check.detail)
                                    .font(.caption2)
                                    .foregroundStyle(Color("TextSecondary"))
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color("SecondaryBlue").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button("settings.save_security_preferences".localized) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                    viewModel.persistPreferences()
                }
            }
            .font(Theme.captionFont)
            .buttonStyle(.bordered)
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private func iconName(for status: SecurityAuditCheck.Status) -> String {
        switch status {
        case .passed:
            return "checkmark.seal.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .failed:
            return "xmark.octagon.fill"
        }
    }

    private func iconColor(for status: SecurityAuditCheck.Status) -> Color {
        switch status {
        case .passed:
            return .green
        case .warning:
            return .orange
        case .failed:
            return .red
        }
    }

    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
        return [GridItem(.flexible())]
    }

    private var statusAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.statusMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.statusMessage = nil
                }
            }
        )
    }

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("settings.notifications".localized, systemImage: "bell.badge")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Toggle("settings.notifications_enabled".localized, isOn: $viewModel.notificationsEnabled)
                .tint(Color("PrimaryBlue"))

            DatePicker("settings.morning_reminder".localized, selection: $viewModel.morningNotificationTime, displayedComponents: .hourAndMinute)
                .disabled(!viewModel.notificationsEnabled)

            DatePicker("settings.evening_reminder".localized, selection: $viewModel.eveningNotificationTime, displayedComponents: .hourAndMinute)
                .disabled(!viewModel.notificationsEnabled)

            Toggle("settings.weekly_report_notification".localized, isOn: $viewModel.weeklyReportEnabled)
                .tint(Color("PrimaryBlue"))

            Button("settings.save_notification_settings".localized) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {}
                Task { await viewModel.persistNotificationState() }
            }
            .font(Theme.captionFont)
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryBlue"))
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var dataSourceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("settings.data_sources".localized, systemImage: "externaldrive.badge.icloud")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Toggle("settings.healthkit_sync".localized, isOn: $viewModel.healthKitSyncEnabled)
                .tint(Color("PrimaryBlue"))

            Toggle("settings.calendar_sync".localized, isOn: $viewModel.calendarSyncEnabled)
                .tint(Color("PrimaryBlue"))

            Text("settings.data_source_apply_info".localized)
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            Button("settings.update_data_sources".localized) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                    viewModel.persistPreferences()
                }
            }
            .font(Theme.captionFont)
            .buttonStyle(.bordered)
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var personalizationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("settings.theme_and_language".localized, systemImage: "paintpalette")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Picker("settings.theme".localized, selection: $viewModel.preferredTheme) {
                ForEach(UserDefaultsManager.AppTheme.allCases, id: \.self) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .pickerStyle(.segmented)

            Picker("settings.insight_tone".localized, selection: $viewModel.preferredInsightTone) {
                Text("settings.insight_tone_short".localized).tag(UserDefaultsManager.InsightTone.concise)
                Text("settings.insight_tone_detailed".localized).tag(UserDefaultsManager.InsightTone.detailed)
            }
            .pickerStyle(.segmented)

            Button("settings.save_preferences".localized) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                    viewModel.persistPreferences()
                }
            }
            .font(Theme.captionFont)
            .buttonStyle(.bordered)
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("settings.export".localized, systemImage: "square.and.arrow.up")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("settings.export_info".localized)
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            Button("settings.export_csv".localized) {
                do {
                    shareURL = try viewModel.exportSettingsSnapshot()
                    isShareSheetPresented = shareURL != nil
                    viewModel.statusMessage = nil
                } catch {
                    viewModel.statusMessage = "settings.export_failed".localized(with: error.localizedDescription)
                }
            }
            .font(Theme.captionFont)
            .buttonStyle(.borderedProminent)
            .tint(Color("SecondaryBlue"))
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("settings.account".localized, systemImage: "person.crop.circle")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text(viewModel.accountEmail)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("settings.reset_onboarding_info".localized)
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            if let router {
                Button("settings.view_profile".localized) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        router.navigate(to: .profile)
                    }
                }
                .font(Theme.captionFont)
                .buttonStyle(.borderedProminent)
                .tint(Color("SecondaryBlue"))
            }

            Button("settings.reset_account_prefs".localized) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                    viewModel.resetOnboardingAndPreferences()
                }
            }
            .font(Theme.captionFont)
            .buttonStyle(.bordered)
            .tint(Color("MoodBad"))
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}
