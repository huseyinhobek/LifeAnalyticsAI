// MARK: - Tests.NotificationContentBuilder

import XCTest
@testable import LifeAnalyticsAI

final class NotificationContentBuilderTests: XCTestCase {
    func testMorningBodyFallbackContainsConcretePatternNumber() {
        let text = NotificationContentBuilder.morningBody(streakDays: 5, predictionText: nil)

        XCTAssertTrue(text.contains("5"))
        XCTAssertTrue(text.contains("7"))
    }

    func testMorningBodyAppendsPatternHintWhenPredictionHasNoNumber() {
        let text = NotificationContentBuilder.morningBody(streakDays: 2, predictionText: "Bugun enerjin yuksek")

        XCTAssertTrue(text.contains("7"))
        XCTAssertTrue(text.contains("patern"))
    }

    func testEveningBodyClampsWeeklyCheckInCountToSeven() {
        let high = NotificationContentBuilder.eveningBody(moodCheckInsThisWeek: 99)
        let low = NotificationContentBuilder.eveningBody(moodCheckInsThisWeek: -4)

        XCTAssertTrue(high.contains("7/7"))
        XCTAssertTrue(low.contains("0/7"))
    }

    func testWeeklyBodyNeverUsesNegativeTrackedDayCount() {
        let text = NotificationContentBuilder.weeklyBody(trackedDays: -9)

        XCTAssertTrue(text.contains("0"))
        XCTAssertTrue(text.contains("patern"))
    }
}
