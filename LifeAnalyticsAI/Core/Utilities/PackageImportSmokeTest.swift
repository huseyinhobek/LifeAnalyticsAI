// MARK: - Core.Utilities

import Foundation
import KeychainAccess
import SwiftDate

enum PackageImportSmokeTest {
    static func verify() {
        _ = Keychain(service: "com.lifeanalyticsai.app")
        _ = DateInRegion()
    }
}
