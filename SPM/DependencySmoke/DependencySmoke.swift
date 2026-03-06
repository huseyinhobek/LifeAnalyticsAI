// MARK: - SPM.DependencySmoke

import Foundation
import KeychainAccess
import SwiftDate

public enum DependencySmoke {
    public static func validateImports() {
        _ = Keychain(service: "com.lifeanalyticsai.smoke")
        _ = DateInRegion()
    }
}
