// MARK: - Core.Utilities

import Foundation
import Observation
import OSLog
import StoreKit

@Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    private static let dailyKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LifeAnalyticsAI",
        category: "Subscription"
    )

    var products: [Product] = []
    var isPremium = false
    var isLoading = false
    var errorMessage: String?

    var monthlyProduct: Product? {
        products.first { $0.id == AppConstants.Subscription.monthlyID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == AppConstants.Subscription.yearlyID }
    }

    var yearlyMonthlyEquivalent: String? {
        guard let yearly = yearlyProduct else { return nil }
        let yearlyAmount = NSDecimalNumber(decimal: yearly.price)
        let monthlyEquivalent = yearlyAmount.dividing(by: NSDecimalNumber(value: 12)).decimalValue
        return yearly.priceFormatStyle.format(monthlyEquivalent)
    }

    var savingsPercentage: Int {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return 0 }
        let yearlyTotal = NSDecimalNumber(decimal: yearly.price).doubleValue
        let monthlyTotal = NSDecimalNumber(decimal: monthly.price).doubleValue * 12
        guard monthlyTotal > 0 else { return 0 }
        return Int(((monthlyTotal - yearlyTotal) / monthlyTotal * 100).rounded())
    }

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: AppConstants.Subscription.allProductIDs)
                .sorted { $0.price < $1.price }
            logger.info("Loaded products count: \(self.products.count)")
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            errorMessage = "error.products_load".localized
        }
    }

    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case let .success(verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            logger.info("Purchase successful: \(product.id)")
            return true

        case .userCancelled:
            logger.info("Purchase cancelled")
            return false

        case .pending:
            logger.info("Purchase pending")
            return false

        @unknown default:
            return false
        }
    }

    @MainActor
    func restore() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            logger.info("Restore completed, premium: \(self.isPremium)")
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            errorMessage = "error.restore_failed".localized
        }
    }

    func updateSubscriptionStatus() async {
        var hasActiveEntitlement = false

        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result,
               AppConstants.Subscription.allProductIDs.contains(transaction.productID),
               transaction.revocationDate == nil,
               !transaction.isUpgraded {
                hasActiveEntitlement = true
            }
        }

        let entitlementActive = hasActiveEntitlement

        await MainActor.run {
            self.isPremium = entitlementActive
            self.logger.info("Subscription status updated, premium: \(entitlementActive)")
        }
    }

    func hasAccess(to feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedInsights,
             .weeklyReport,
             .crossCorrelation,
             .predictions,
             .extendedTrends,
             .fullInsightHistory,
             .dataExport,
             .priorityAI:
            return isPremium
        }
    }

    var dailyInsightsRemaining: Int {
        if isPremium { return 999 }
        let used = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite)?.integer(forKey: dailyCounterKey) ?? 0
        return max(0, AppConstants.Subscription.freeInsightsPerDay - used)
    }

    func recordInsightUsage() {
        guard !isPremium else { return }
        let defaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite) ?? .standard
        let current = defaults.integer(forKey: dailyCounterKey)
        defaults.set(current + 1, forKey: dailyCounterKey)
    }

    func isEligibleForTrial() async -> Bool {
        for product in products {
            if let subscription = product.subscription {
                return await subscription.isEligibleForIntroOffer
            }
        }
        return false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [self] in
            for await result in Transaction.updates {
                guard case let .verified(transaction) = result else { continue }
                await transaction.finish()
                await updateSubscriptionStatus()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case let .verified(value):
            return value
        }
    }

    private var dailyCounterKey: String {
        "insights_used_\(Self.dailyKeyFormatter.string(from: Date()))"
    }
}

enum SubscriptionError: LocalizedError {
    case verificationFailed
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "error.verification_failed".localized
        case .purchaseFailed:
            return "error.purchase_failed".localized
        }
    }
}
