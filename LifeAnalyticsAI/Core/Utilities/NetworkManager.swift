// MARK: - Core.Utilities

import Foundation

actor NetworkManager {
    static let shared = NetworkManager()

    private let session: URLSession
    private let sslPinningDelegate: SSLPinningDelegate
    private let parser: LLMResponseParsing
    private let credentialStore: SecureCredentialStore
    private let maxRetryCount = 2

    init(
        parser: LLMResponseParsing = LLMResponseParser(),
        credentialStore: SecureCredentialStore = .shared
    ) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        let sslPinningDelegate = SSLPinningDelegate(
            pinnedHosts: AppConstants.API.llmPinnedHosts,
            pinnedSPKIHashes: AppConstants.API.llmPinnedSPKIHashes
        )
        self.sslPinningDelegate = sslPinningDelegate
        session = URLSession(configuration: config, delegate: sslPinningDelegate, delegateQueue: nil)
        self.parser = parser
        self.credentialStore = credentialStore
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

        guard let apiKey = try await credentialStore.getAnthropicAPIKey(), !apiKey.isEmpty else {
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

        return try parser.parse(data: data, response: response)
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
