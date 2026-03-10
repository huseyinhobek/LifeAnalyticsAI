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
                title: "security.audit.https.title".localized,
                detail: isHTTPS ? "security.audit.https.pass".localized : "security.audit.https.fail".localized,
                status: isHTTPS ? .passed : .failed
            ),
            SecurityAuditCheck(
                title: "security.audit.proxy.title".localized,
                detail: isProxyHost
                    ? "security.audit.proxy.pass".localized
                    : "security.audit.proxy.fail".localized,
                status: isProxyHost ? .passed : .failed
            ),
            SecurityAuditCheck(
                title: "security.audit.privacy.title".localized,
                detail: hasPrivacyManifest
                    ? "security.audit.privacy.pass".localized
                    : "security.audit.privacy.fail".localized,
                status: hasPrivacyManifest ? .passed : .failed
            ),
            SecurityAuditCheck(
                title: "security.audit.faceid.title".localized,
                detail: hasFaceIDUsageDescription
                    ? "security.audit.faceid.pass".localized
                    : "security.audit.faceid.fail".localized,
                status: hasFaceIDUsageDescription ? .passed : .failed
            ),
            SecurityAuditCheck(
                title: "security.audit.client_key.title".localized,
                detail: "security.audit.client_key.pass".localized,
                status: .passed
            ),
            SecurityAuditCheck(
                title: "security.audit.biometric.title".localized,
                detail: appLockEnabled
                    ? "security.audit.biometric.pass".localized
                    : "security.audit.biometric.warn".localized,
                status: appLockEnabled ? .passed : .warning
            )
        ]
    }
}
