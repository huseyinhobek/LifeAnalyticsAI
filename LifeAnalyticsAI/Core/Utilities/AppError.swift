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
    case securityError(message: String)
    case persistenceError(underlying: Error)
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "Bu cihazda HealthKit kullanilamamaktadir."
        case .healthKitAuthorizationDenied:
            return "Saglik verilerine erisim izni gereklidir."
        case .calendarAccessDenied:
            return "Takvim verilerine erisim izni gereklidir."
        case .dataNotFound:
            return "Istenen veri bulunamadi."
        case let .insufficientData(required, current):
            return "Icgoru icin en az \(required) gunluk veri gerekli. Mevcut: \(current) gun."
        case let .networkError(underlying):
            return "Ag hatasi olustu: \(underlying.localizedDescription)"
        case let .llmError(message):
            return "LLM hatasi: \(message)"
        case let .securityError(message):
            return "Guvenlik hatasi: \(message)"
        case let .persistenceError(underlying):
            return "Kayit hatasi olustu: \(underlying.localizedDescription)"
        case let .unknown(underlying):
            return "Bilinmeyen hata: \(underlying.localizedDescription)"
        }
    }
}

struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content.alert(
            "Hata",
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
            Button("Tamam", role: .cancel) {
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
