// MARK: - Core.Utilities

import Foundation

#if canImport(LocalAuthentication)
import LocalAuthentication

enum BiometricAuthenticator {
    static func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Iptal"
        var authError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            throw AppError.securityError(message: "Biyometrik dogrulama kullanilamiyor")
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            throw AppError.securityError(message: "Biyometrik dogrulama basarisiz")
        }
    }
}
#else
enum BiometricAuthenticator {
    static func authenticate(reason: String) async throws -> Bool {
        _ = reason
        return true
    }
}
#endif
