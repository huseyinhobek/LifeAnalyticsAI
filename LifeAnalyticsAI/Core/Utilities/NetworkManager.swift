// MARK: - Core.Utilities

import Foundation
import OSLog

actor NetworkManager {
    static let shared = NetworkManager()
    private let session: URLSession
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.lifeanalytics.app",
        category: "Network"
    )

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    // MARK: - Health Check

    func checkProxyHealth() async -> Bool {
        guard let url = URL(string: AppConstants.API.healthCheckURL) else { return false }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                logger.info("Proxy health check: \(status)")
                return status == "ok"
            }

            return false
        } catch {
            logger.error("Proxy health check failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - LLM Request

    func sendLLMRequest(prompt: String, systemPrompt: String) async throws -> String {
        guard let url = URL(string: AppConstants.API.llmBaseURL) else {
            throw AppError.networkError(underlying: URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "prompt": prompt,
            "system_prompt": systemPrompt,
            "model": AppConstants.API.llmModel,
            "max_tokens": AppConstants.API.maxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        logger.info("LLM request sending to proxy (prompt length: \(prompt.count))")
        let startTime = Date()

        var lastError: Error?
        for attempt in 0..<3 {
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AppError.networkError(underlying: URLError(.badServerResponse))
                }

                let duration = Date().timeIntervalSince(startTime)
                logger.info(
                    "LLM response received in \(String(format: "%.1f", duration))s (status: \(httpResponse.statusCode))"
                )

                switch httpResponse.statusCode {
                case 200:
                    return try parseAnthropicResponse(data: data)
                case 400:
                    let errorMsg = parseErrorMessage(data: data)
                    throw AppError.llmError(message: "Gecersiz istek: \(errorMsg)")
                case 401:
                    throw AppError.llmError(message: "Yetkilendirme hatasi")
                case 429:
                    throw AppError.llmError(message: "Cok fazla istek. Lutfen biraz bekle.")
                case 500...599:
                    lastError = AppError.llmError(message: "Sunucu hatasi (\(httpResponse.statusCode))")
                    if attempt < 2 {
                        try await Task.sleep(nanoseconds: UInt64((attempt + 1) * 2_000_000_000))
                        continue
                    }
                    throw lastError ?? AppError.llmError(message: "Sunucu hatasi")
                default:
                    throw AppError.llmError(message: "Beklenmeyen hata: \(httpResponse.statusCode)")
                }
            } catch {
                lastError = error
                if let appError = error as? AppError {
                    throw appError
                }

                if attempt < 2 {
                    logger.warning(
                        "LLM request failed (attempt \(attempt + 1)): \(error.localizedDescription). Retrying..."
                    )
                    try await Task.sleep(nanoseconds: UInt64((attempt + 1) * 2_000_000_000))
                    continue
                }
            }
        }

        throw AppError.networkError(underlying: lastError ?? URLError(.unknown))
    }

    // MARK: - Response Parsing

    private func parseAnthropicResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw AppError.llmError(message: "Yanit parse edilemedi")
        }

        let textParts = content.compactMap { block -> String? in
            guard let type = block["type"] as? String,
                  type == "text",
                  let text = block["text"] as? String else {
                return nil
            }
            return text
        }

        let fullText = textParts.joined(separator: "\n")
        guard !fullText.isEmpty else {
            throw AppError.llmError(message: "Bos yanit alindi")
        }

        return fullText
    }

    private func parseErrorMessage(data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? String {
            return error
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorObj = json["error"] as? [String: Any],
           let message = errorObj["message"] as? String {
            return message
        }

        return "Bilinmeyen hata"
    }
}
