// MARK: - Tests.CorrelationSignificanceCalculator

import XCTest
@testable import LifeAnalyticsAI

final class CorrelationSignificanceCalculatorTests: XCTestCase {
    func testExecuteReturnsSignificantForStrongCorrelation() async {
        let calculator = CorrelationSignificanceCalculator()

        let result = await calculator.execute(correlation: 0.72, sampleSize: 30, alpha: 0.05)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isSignificant ?? false)
        XCTAssertLessThan(result?.pValue ?? 1, 0.05)
    }

    func testExecuteReturnsNotSignificantForWeakCorrelation() async {
        let calculator = CorrelationSignificanceCalculator()

        let result = await calculator.execute(correlation: 0.08, sampleSize: 30, alpha: 0.05)

        XCTAssertNotNil(result)
        XCTAssertFalse(result?.isSignificant ?? true)
        XCTAssertGreaterThan(result?.pValue ?? 0, 0.05)
    }

    func testExecuteReturnsNilWhenSampleTooSmall() async {
        let calculator = CorrelationSignificanceCalculator()

        let result = await calculator.execute(correlation: 0.9, sampleSize: 3, alpha: 0.05)

        XCTAssertNil(result)
    }
}
