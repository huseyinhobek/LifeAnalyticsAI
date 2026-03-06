// MARK: - Core.Utilities

import Foundation
import KeychainAccess

actor NetworkManager {
    static let shared = NetworkManager()

    private let session: URLSession
    private let keychain = Keychain(service: AppConstants.Storage.keychainService)
    private let maxRetryCount = 2

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    func sendLLMRequest(prompt: String, systemPrompt: String) async throws -> String {
        var lastError: Error?

        for attempt in 0...maxRetryCount {
            do {
                return try await performLLMRequest(prompt: prompt, systemPrompt: systemPrompt)
            } catch {
                lastError = error
                let shouldRetry = attempt < maxRetryCount && isRetryable(error: error)
                if !shouldRetry {
                    throw normalize(error)
                }
            }
        }

        throw normalize(lastError ?? AppError.llmError(message: "Bilinmeyen ag hatasi"))
    }

    private func performLLMRequest(prompt: String, systemPrompt: String) async throws -> String {
        guard let url = URL(string: AppConstants.API.llmBaseURL) else {
            throw AppError.llmError(message: "Gecersiz LLM URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        guard let apiKey = try keychain.get("anthropic_api_key"), !apiKey.isEmpty else {
            throw AppError.llmError(message: "Anthropic API anahtari bulunamadi")
        }

        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let body = LLMRequestBody(
            model: AppConstants.API.llmModel,
            maxTokens: AppConstants.API.maxTokens,
            messages: [LLMRequestBody.Message(role: "user", content: prompt)],
            system: systemPrompt
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw AppError.llmError(message: "LLM istek govdesi olusturulamadi")
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AppError.networkError(underlying: error)
        }

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

    private func isRetryable(error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost, .cannotFindHost:
                return true
            default:
                return false
            }
        }

        if case let AppError.networkError(underlying) = error,
           let networkFailure = underlying as? NetworkFailure,
           case let .httpStatus(code) = networkFailure {
            return (500...599).contains(code)
        }

        return false
    }

    private func normalize(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return AppError.networkError(underlying: error)
    }
}

private struct LLMRequestBody: Encodable {
    let model: String
    let maxTokens: Int
    let messages: [Message]
    let system: String

    struct Message: Encodable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
    }
}

private struct LLMResponseBody: Decodable {
    let content: [Content]

    struct Content: Decodable {
        let type: String
        let text: String?
    }
}

private struct LLMErrorEnvelope: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}

private enum NetworkFailure: Error {
    case invalidResponse
    case httpStatus(code: Int)
}
