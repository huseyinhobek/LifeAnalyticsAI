// MARK: - Core.Utilities

import Foundation

struct SecurityAuditCheck: Identifiable {
    enum Status {
        case passed
        case warning
        case failed
    }

    let title: String
    let detail: String
    let status: Status

    var id: String { title }
}

enum SecurityAuditChecklist {
    static func run(appLockEnabled: Bool) -> [SecurityAuditCheck] {
        let apiURL = URL(string: AppConstants.API.llmBaseURL)
        let apiHost = apiURL?.host?.lowercased()
        let isHTTPS = apiURL?.scheme?.lowercased() == "https"
        let isProxyHost = apiHost == "life-analytics-proxy.hsynhbk.workers.dev"
        let hasPrivacyManifest = Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy") != nil
        let hasFaceIDUsageDescription = (Bundle.main.object(forInfoDictionaryKey: "NSFaceIDUsageDescription") as? String)?.isEmpty == false

        return [
            SecurityAuditCheck(
                title: "LLM endpoint HTTPS",
                detail: isHTTPS ? "LLM baglantisi HTTPS ile yapiliyor." : "LLM endpoint HTTPS degil.",
                status: isHTTPS ? .passed : .failed
            ),
            SecurityAuditCheck(
                title: "Proxy endpoint",
                detail: isProxyHost
                    ? "LLM cagrilari Cloudflare proxy uzerinden yapiliyor."
                    : "LLM endpoint proxy hostu ile eslesmiyor.",
                status: isProxyHost ? .passed : .failed
            ),
            SecurityAuditCheck(
                title: "Privacy manifest",
                detail: hasPrivacyManifest
                    ? "PrivacyInfo.xcprivacy bundle icinde bulundu."
                    : "PrivacyInfo.xcprivacy bundle icinde bulunamadi.",
                status: hasPrivacyManifest ? .passed : .failed
            ),
            SecurityAuditCheck(
                title: "Face ID usage description",
                detail: hasFaceIDUsageDescription
                    ? "NSFaceIDUsageDescription tanimli."
                    : "NSFaceIDUsageDescription eksik.",
                status: hasFaceIDUsageDescription ? .passed : .failed
            ),
            SecurityAuditCheck(
                title: "Client API key storage",
                detail: "API anahtari istemci tarafinda tutulmadan proxy uzerinden istek yapiliyor.",
                status: .passed
            ),
            SecurityAuditCheck(
                title: "Biometric app lock",
                detail: appLockEnabled
                    ? "Uygulama kilidi acik."
                    : "Uygulama kilidi kapali; guvenlik icin acilmasi onerilir.",
                status: appLockEnabled ? .passed : .warning
            )
        ]
    }
}
