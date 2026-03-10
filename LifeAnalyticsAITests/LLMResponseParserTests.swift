// MARK: - Tests.LLMResponseParser

import XCTest
@testable import LifeAnalyticsAI

final class LLMResponseParserTests: XCTestCase {
    func testParseReturnsConcatenatedTextBlocks() throws {
        let parser = LLMResponseParser()
        let data = """
        {
          "content": [
            { "type": "text", "text": "Merhaba" },
            { "type": "text", "text": "Dunya" }
          ]
        }
        """.data(using: .utf8)!

        let response = makeHTTPResponse(statusCode: 200)
        let text = try parser.parse(data: data, response: response)

        XCTAssertEqual(text, "Merhaba\nDunya")
    }

    func testParseReturnsAPIErrorMessage() {
        let parser = LLMResponseParser()
        let data = """
        {
          "error": { "message": "Rate limit" }
        }
        """.data(using: .utf8)!

        let response = makeHTTPResponse(statusCode: 429)

        XCTAssertThrowsError(try parser.parse(data: data, response: response)) { error in
            guard case let AppError.llmError(message) = error else {
                return XCTFail("Expected llmError")
            }
            XCTAssertEqual(message, "Rate limit")
        }
    }

    func testParseReturnsEmptyTextError() {
        let parser = LLMResponseParser()
        let data = """
        {
          "content": [
            { "type": "text", "text": "" }
          ]
        }
        """.data(using: .utf8)!

        let response = makeHTTPResponse(statusCode: 200)

        XCTAssertThrowsError(try parser.parse(data: data, response: response)) { error in
            guard case let AppError.llmError(message) = error else {
                return XCTFail("Expected llmError")
            }
            XCTAssertEqual(message, "LLM yaniti bos geldi")
        }
    }

    private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
