// MARK: - Tests.LLMUsageTracker

import XCTest
@testable import LifeAnalyticsAI

final class LLMUsageTrackerTests: XCTestCase {
    func testTrackerEnforcesDailyAndMonthlyLimits() async {
        let suiteName = "tests.llm.usage.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removePersistentDomain(forName: suiteName)

        let tracker = LLMUsageTracker(dailyLimit: 10, monthlyLimit: 12, defaults: defaults)

        let canConsumeEight = await tracker.canConsume(tokens: 8, at: date("2026-03-06"))
        XCTAssertTrue(canConsumeEight)
        await tracker.record(tokens: 8, at: date("2026-03-06"))

        let canConsumeThree = await tracker.canConsume(tokens: 3, at: date("2026-03-06"))
        XCTAssertFalse(canConsumeThree)
        let canConsumeTwo = await tracker.canConsume(tokens: 2, at: date("2026-03-06"))
        XCTAssertTrue(canConsumeTwo)

        let canConsumeFour = await tracker.canConsume(tokens: 4, at: date("2026-03-07"))
        XCTAssertTrue(canConsumeFour)
        await tracker.record(tokens: 4, at: date("2026-03-07"))
        let canConsumeOne = await tracker.canConsume(tokens: 1, at: date("2026-03-08"))
        XCTAssertFalse(canConsumeOne)

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

        let firstAllowed = await limiter.isAllowed(at: first)
        XCTAssertTrue(firstAllowed)
        await limiter.recordRequest(at: first)
        let secondAllowed = await limiter.isAllowed(at: second)
        XCTAssertTrue(secondAllowed)
        await limiter.recordRequest(at: second)
        let thirdAllowed = await limiter.isAllowed(at: third)
        XCTAssertFalse(thirdAllowed)

        let afterWindowAllowed = await limiter.isAllowed(at: afterWindow)
        XCTAssertTrue(afterWindowAllowed)
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
