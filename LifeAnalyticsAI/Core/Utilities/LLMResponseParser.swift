// MARK: - Core.Utilities

import Foundation

protocol LLMResponseParsing {
    func parse(data: Data, response: URLResponse) throws -> String
}

struct LLMResponseParser: LLMResponseParsing {
    func parse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError(underlying: NetworkFailure.invalidResponse)
        }

        guard 200...299 ~= httpResponse.statusCode else {
            if let apiError = try? JSONDecoder().decode(LLMErrorEnvelope.self, from: data) {
                throw AppError.llmError(message: apiError.error.message)
            }
            throw AppError.networkError(underlying: NetworkFailure.httpStatus(code: httpResponse.statusCode))
        }

        do {
            let decoded = try JSONDecoder().decode(LLMResponseBody.self, from: data)
            let text = decoded.content
                .filter { $0.type == "text" }
                .compactMap(\.text)
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !text.isEmpty else {
                throw AppError.llmError(message: "LLM yaniti bos geldi")
            }

            return text
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.llmError(message: "LLM yaniti cozumlenemedi")
        }
    }
}

struct LLMResponseBody: Decodable {
    let content: [Content]

    struct Content: Decodable {
        let type: String
        let text: String?
    }
}

struct LLMErrorEnvelope: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}

enum NetworkFailure: Error {
    case invalidResponse
    case httpStatus(code: Int)
}
