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
        let apiHost = apiURL?.host
        let isHTTPS = apiURL?.scheme?.lowercased() == "https"
        let hasPinHashes = !AppConstants.API.llmPinnedSPKIHashes.isEmpty
        let hostIsPinned = apiHost.map { AppConstants.API.llmPinnedHosts.contains($0) } ?? false
        let hasPrivacyManifest = Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy") != nil
        let hasFaceIDUsageDescription = (Bundle.main.object(forInfoDictionaryKey: "NSFaceIDUsageDescription") as? String)?.isEmpty == false
        let hasKeychainServiceName = !AppConstants.Storage.keychainService.isEmpty

        return [
            SecurityAuditCheck(
                title: "LLM endpoint HTTPS",
                detail: isHTTPS ? "LLM baglantisi HTTPS ile yapiliyor." : "LLM endpoint HTTPS degil.",
                status: isHTTPS ? .passed : .failed
            ),
            SecurityAuditCheck(
                title: "SSL pinning",
                detail: hasPinHashes && hostIsPinned
                    ? "Pinned host ve SPKI hash ayarlari mevcut."
                    : "Pinned host veya SPKI hash ayari eksik.",
                status: hasPinHashes && hostIsPinned ? .passed : .failed
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
                title: "Keychain configuration",
                detail: hasKeychainServiceName
                    ? "Keychain service identifier tanimli."
                    : "Keychain service identifier bos.",
                status: hasKeychainServiceName ? .passed : .failed
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
