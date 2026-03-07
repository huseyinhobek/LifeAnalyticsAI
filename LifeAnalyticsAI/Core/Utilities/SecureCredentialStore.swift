// MARK: - Core.Utilities

import Foundation
import KeychainAccess

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

actor SecureCredentialStore: SecureCredentialStoreProtocol {
    static let shared = SecureCredentialStore()

    private let keychain: Keychain
    private var sessionCachedAPIKey: String?

    init(keychain: Keychain = Keychain(service: AppConstants.Storage.keychainService)) {
        self.keychain = keychain
    }

    func setAnthropicAPIKey(_ apiKey: String, requireBiometric: Bool) async throws {
        try keychain.set(apiKey, key: AppConstants.Storage.Keys.anthropicAPIKey)
        try keychain.set(requireBiometric ? "1" : "0", key: AppConstants.Storage.Keys.anthropicAPIKeyBiometricRequired)
        sessionCachedAPIKey = nil
    }

    func getAnthropicAPIKey(localizedReason: String = "API anahtarina erisim icin kimlik dogrulama gerekli") async throws -> String? {
        if let sessionCachedAPIKey {
            return sessionCachedAPIKey
        }

        let requiresBiometric = (try keychain.get(AppConstants.Storage.Keys.anthropicAPIKeyBiometricRequired)) == "1"
        if requiresBiometric {
            try await validateBiometricAccess(localizedReason: localizedReason)
        }

        let apiKey = try keychain.get(AppConstants.Storage.Keys.anthropicAPIKey)
        if let apiKey, !apiKey.isEmpty {
            sessionCachedAPIKey = apiKey
        }
        return apiKey
    }

    func clearAnthropicAPIKey() async throws {
        try keychain.remove(AppConstants.Storage.Keys.anthropicAPIKey)
        try keychain.remove(AppConstants.Storage.Keys.anthropicAPIKeyBiometricRequired)
        sessionCachedAPIKey = nil
    }

    private func validateBiometricAccess(localizedReason: String) async throws {
#if canImport(LocalAuthentication)
        let context = LAContext()
        var authError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            throw AppError.securityError(message: "Biyometrik dogrulama kullanilamiyor")
        }

        let isAuthorized = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: localizedReason
        )

        guard isAuthorized else {
            throw AppError.securityError(message: "Biyometrik dogrulama basarisiz")
        }
#else
        _ = localizedReason
#endif
    }
}
