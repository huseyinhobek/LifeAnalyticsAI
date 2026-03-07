// MARK: - Core.Utilities

import Foundation
import Observation
import OSLog

@Observable
final class ProxyHealthChecker {
    static let shared = ProxyHealthChecker()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.lifeanalytics.app",
        category: "ProxyHealth"
    )

    var isProxyAvailable: Bool = true
    var lastCheckTime: Date?

    func performHealthCheck() async {
        let available = await NetworkManager.shared.checkProxyHealth()
        await MainActor.run {
            self.isProxyAvailable = available
            self.lastCheckTime = Date()
        }

        if !available {
            logger.warning("Proxy is not available - offline fallback will be used")
        }
    }

    func startPeriodicCheck(interval: TimeInterval = 300) {
        Task {
            while !Task.isCancelled {
                await performHealthCheck()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
}
