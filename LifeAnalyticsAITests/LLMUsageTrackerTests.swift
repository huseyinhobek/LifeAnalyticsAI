// MARK: - Tests.LLMUsageTracker

import XCTest
@testable import LifeAnalyticsAI

final class LLMUsageTrackerTests: XCTestCase {
    func testTrackerEnforcesDailyAndMonthlyLimits() async {
        let suiteName = "tests.llm.usage.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removePersistentDomain(forName: suiteName)

        let tracker = LLMUsageTracker(dailyLimit: 10, monthlyLimit: 12, defaults: defaults)

        XCTAssertTrue(await tracker.canConsume(tokens: 8, at: date("2026-03-06")))
        await tracker.record(tokens: 8, at: date("2026-03-06"))

        XCTAssertFalse(await tracker.canConsume(tokens: 3, at: date("2026-03-06")))
        XCTAssertTrue(await tracker.canConsume(tokens: 2, at: date("2026-03-06")))

        XCTAssertTrue(await tracker.canConsume(tokens: 4, at: date("2026-03-07")))
        await tracker.record(tokens: 4, at: date("2026-03-07"))
        XCTAssertFalse(await tracker.canConsume(tokens: 1, at: date("2026-03-08")))

        defaults?.removePersistentDomain(forName: suiteName)
    }

    func testRateLimiterAllowsOnlyConfiguredRequestsPerHour() async {
        let suiteName = "tests.llm.rateLimiter.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removePersistentDomain(forName: suiteName)

        let limiter = LLMRateLimiter(maxRequestsPerHour: 2, defaults: defaults)
        let first = date("2026-03-06")
        let second = first.addingTimeInterval(300)
        let third = first.addingTimeInterval(600)
        let afterWindow = first.addingTimeInterval(3700)

        XCTAssertTrue(await limiter.isAllowed(at: first))
        await limiter.recordRequest(at: first)
        XCTAssertTrue(await limiter.isAllowed(at: second))
        await limiter.recordRequest(at: second)
        XCTAssertFalse(await limiter.isAllowed(at: third))

        XCTAssertTrue(await limiter.isAllowed(at: afterWindow))
        defaults?.removePersistentDomain(forName: suiteName)
    }

    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string) ?? Date()
    }
}
