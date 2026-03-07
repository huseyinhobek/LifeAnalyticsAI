// MARK: - Presentation.Screens.Settings

import SwiftUI

struct LanguageSelectionView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(LanguageManager.AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            languageManager.currentLanguage = lang
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Text(lang.flag)
                                .font(.title2)

                            Text(lang.displayName)
                                .font(.body)
                                .foregroundStyle(Color("TextPrimary"))

                            Spacer()

                            if languageManager.currentLanguage == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color("PrimaryBlue"))
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("settings.language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("general.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}
