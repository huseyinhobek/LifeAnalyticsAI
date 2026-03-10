// MARK: - Core.Extensions

import Foundation

extension String {
    var localized: String {
        let lang = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite)?
            .string(forKey: "app_language") ?? "en"
        let path = Bundle.main.path(forResource: lang, ofType: "lproj")
        let bundle = path.flatMap(Bundle.init(path:)) ?? .main
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }

    func localized(with args: CVarArg...) -> String {
        String(format: localized, arguments: args)
    }
}
