// MARK: - Presentation.Screens.Settings

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    var router: NavigationRouter?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var shareURL: URL?
    @State private var isShareSheetPresented = false
    @FocusState private var isAPIKeyFieldFocused: Bool

    init(viewModel: SettingsViewModel, router: NavigationRouter? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Theme.paddingMedium) {
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
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDismissOnTap()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Tamam") {
                    isAPIKeyFieldFocused = false
                }
            }
        }
        .alert("Bilgi", isPresented: statusAlertBinding) {
            Button("Tamam", role: .cancel) {
                viewModel.statusMessage = nil
            }
        } message: {
            Text(viewModel.statusMessage ?? "")
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

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Guvenlik", systemImage: "lock.shield")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            TextField("Anthropic API Key", text: $viewModel.anthropicAPIKeyDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .focused($isAPIKeyFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    isAPIKeyFieldFocused = false
                }

            Toggle("Biyometrik koruma", isOn: $viewModel.requireBiometricForAPIKey)
                .tint(Color("PrimaryBlue"))

            Toggle("Uygulama kilidi (Face ID/Touch ID)", isOn: $viewModel.appLockEnabled)
                .tint(Color("PrimaryBlue"))

            Text("API anahtari cihaz keychain'inde saklanir. Biyometrik koruma acik oldugunda erisim Face ID/Touch ID ile dogrulanir.")
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 10) {
                Button("API Key Kaydet") {
                    isAPIKeyFieldFocused = false
                    Task { await viewModel.saveAPIKeyToKeychain() }
                }
                .font(Theme.captionFont)
                .buttonStyle(.borderedProminent)
                .tint(Color("PrimaryBlue"))

                Button("API Key Sil") {
                    isAPIKeyFieldFocused = false
                    Task { await viewModel.clearAPIKeyFromKeychain() }
                }
                .font(Theme.captionFont)
                .buttonStyle(.bordered)
                .tint(Color("MoodBad"))
            }

            Button("Guvenlik Denetimini Calistir") {
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

            Button("Guvenlik Tercihlerini Kaydet") {
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
            Label("Bildirim Tercihleri", systemImage: "bell.badge")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Toggle("Bildirimleri Ac", isOn: $viewModel.notificationsEnabled)
                .tint(Color("PrimaryBlue"))

            DatePicker("Sabah Hatirlatma", selection: $viewModel.morningNotificationTime, displayedComponents: .hourAndMinute)
                .disabled(!viewModel.notificationsEnabled)

            DatePicker("Aksam Hatirlatma", selection: $viewModel.eveningNotificationTime, displayedComponents: .hourAndMinute)
                .disabled(!viewModel.notificationsEnabled)

            Toggle("Haftalik rapor bildirimi", isOn: $viewModel.weeklyReportEnabled)
                .tint(Color("PrimaryBlue"))

            Button("Bildirim Ayarlarini Kaydet") {
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
            Label("Veri Kaynaklari", systemImage: "externaldrive.badge.icloud")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Toggle("HealthKit senkronizasyonu", isOn: $viewModel.healthKitSyncEnabled)
                .tint(Color("PrimaryBlue"))

            Toggle("Calendar senkronizasyonu", isOn: $viewModel.calendarSyncEnabled)
                .tint(Color("PrimaryBlue"))

            Text("Degisiklikler bir sonraki veri senkronunda uygulanir.")
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            Button("Veri Kaynaklarini Guncelle") {
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
            Label("Tema ve Dil", systemImage: "paintpalette")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Picker("Tema", selection: $viewModel.preferredTheme) {
                ForEach(UserDefaultsManager.AppTheme.allCases, id: \.self) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .pickerStyle(.segmented)

            Picker("Insight tonu", selection: $viewModel.preferredInsightTone) {
                Text("Kisa").tag(UserDefaultsManager.InsightTone.concise)
                Text("Detayli").tag(UserDefaultsManager.InsightTone.detailed)
            }
            .pickerStyle(.segmented)

            Button("Tercihleri Kaydet") {
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
            Label("Export", systemImage: "square.and.arrow.up")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("Ayarlarin CSV ozetini disa aktarabilirsin.")
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            Button("Ayarlari CSV Olarak Aktar") {
                do {
                    shareURL = try viewModel.exportSettingsSnapshot()
                    isShareSheetPresented = shareURL != nil
                    viewModel.statusMessage = nil
                } catch {
                    viewModel.statusMessage = "Export olusturulamadi: \(error.localizedDescription)"
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
            Label("Hesap", systemImage: "person.crop.circle")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Text(viewModel.accountEmail)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextPrimary"))

            Text("Onboarding'i yeniden baslatmak icin sifirlama yapabilirsin.")
                .font(Theme.captionFont)
                .foregroundStyle(Color("TextSecondary"))

            if let router {
                Button("Profili Goruntule") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        router.navigate(to: .profile)
                    }
                }
                .font(Theme.captionFont)
                .buttonStyle(.borderedProminent)
                .tint(Color("SecondaryBlue"))
            }

            Button("Hesap Tercihlerini Sifirla") {
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
