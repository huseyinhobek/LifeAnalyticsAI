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
    private var periodicTask: Task<Void, Never>?

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
        periodicTask?.cancel()

        periodicTask = Task {
            while !Task.isCancelled {
                await performHealthCheck()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    func stopPeriodicCheck() {
        periodicTask?.cancel()
        periodicTask = nil
    }
}
