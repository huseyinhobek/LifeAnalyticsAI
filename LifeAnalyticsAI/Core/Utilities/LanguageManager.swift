// MARK: - Core.Utilities

import Foundation
import Observation

@Observable
final class LanguageManager {
    enum AppLanguage: String, CaseIterable, Codable {
        case turkish = "tr"
        case english = "en"

        var displayName: String {
            switch self {
            case .turkish:
                return "Turkce"
            case .english:
                return "English"
            }
        }

        var flag: String {
            switch self {
            case .turkish:
                return "🇹🇷"
            case .english:
                return "🇬🇧"
            }
        }

        var systemPromptInstruction: String {
            switch self {
            case .turkish:
                return """
                Sen bir kisisel yasam analisti AI asistansin.
                Tum yanitlarini Turkce ver.
                Kullaniciya "sen" diye hitap et, samimi ama profesyonel bir ton kullan.
                Sayisal verileri metrik sistemde ver (kg, km, saat).
                Tarih formati: gun.ay.yil (orn: 7 Mart 2026).
                """
            case .english:
                return """
                You are a personal life analytics AI assistant.
                Respond entirely in English.
                Address the user as "you" in a friendly but professional tone.
                Use metric system for measurements (kg, km, hours).
                Date format: Month Day, Year (e.g., March 7, 2026).
                """
            }
        }
    }

    var currentLanguage: AppLanguage {
        didSet {
            defaults.set(currentLanguage.rawValue, forKey: languageKey)
        }
    }

    private let defaults: UserDefaults
    private let languageKey = "app_language"

    init(defaults: UserDefaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite) ?? .standard) {
        self.defaults = defaults

        if let saved = defaults.string(forKey: languageKey),
           let lang = AppLanguage(rawValue: saved) {
            currentLanguage = lang
        } else if let deviceLang = Locale.current.language.languageCode?.identifier,
                  deviceLang.hasPrefix("tr") {
            currentLanguage = .turkish
        } else {
            currentLanguage = .english
        }
    }

    func localized(_ key: String) -> String {
        let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj")
        let bundle = path.flatMap(Bundle.init(path:)) ?? .main
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    var aiSystemPrompt: String {
        currentLanguage.systemPromptInstruction
    }
}
