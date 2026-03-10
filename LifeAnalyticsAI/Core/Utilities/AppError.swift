// MARK: - Core.Utilities

import Foundation
import SwiftUI

enum AppError: LocalizedError {
    case healthKitNotAvailable
    case healthKitAuthorizationDenied
    case calendarAccessDenied
    case dataNotFound
    case insufficientData(required: Int, current: Int)
    case networkError(underlying: Error)
    case llmError(message: String)
    case premiumRequired(feature: PremiumFeature)
    case securityError(message: String)
    case persistenceError(underlying: Error)
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "error.healthkit_unavailable".localized
        case .healthKitAuthorizationDenied:
            return "error.healthkit_denied".localized
        case .calendarAccessDenied:
            return "error.calendar_denied".localized
        case .dataNotFound:
            return "error.data_not_found".localized
        case let .insufficientData(required, current):
            return "error.insufficient_data".localized(with: required, current)
        case let .networkError(underlying):
            return "error.network".localized(with: underlying.localizedDescription)
        case let .llmError(message):
            return "error.llm".localized(with: message)
        case let .premiumRequired(feature):
            _ = feature
            return "premium.free_insight_used".localized
        case let .securityError(message):
            return "error.security".localized(with: message)
        case let .persistenceError(underlying):
            return "error.persistence".localized(with: underlying.localizedDescription)
        case let .unknown(underlying):
            return "error.unknown".localized(with: underlying.localizedDescription)
        }
    }
}

struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content.alert(
            "error.title".localized,
            isPresented: Binding(
                get: { error != nil },
                set: { isPresented in
                    if !isPresented {
                        error = nil
                    }
                }
            ),
            presenting: error
        ) { _ in
            Button("general.done".localized, role: .cancel) {
                error = nil
            }
        } message: { appError in
            Text(appError.localizedDescription)
        }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}
