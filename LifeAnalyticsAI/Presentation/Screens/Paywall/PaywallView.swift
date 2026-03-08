// MARK: - Presentation.Screens.Paywall

import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var isTrialEligible = false
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.paddingMedium) {
                    headerSection
                    featuresSection
                    pricingSection
                    ctaSection
                    legalSection
                }
                .padding(.horizontal, Theme.paddingLarge)
                .padding(.bottom, Theme.paddingLarge)
            }
            .background(Color("BackgroundLight"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("general.done".localized)
                            .font(Theme.captionFont.weight(.semibold))
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }
            }
            .task {
                if manager.products.isEmpty {
                    await manager.loadProducts()
                }
                isTrialEligible = await manager.isEligibleForTrial()
                selectedProduct = manager.yearlyProduct ?? manager.monthlyProduct
            }
            .alert("error.purchase_title".localized, isPresented: $showError) {
                Button("error.ok".localized, role: .cancel) { }
            } message: {
                Text(errorText)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color("PrimaryBlue"), Color("SecondaryBlue")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 8)
                .padding(.top, Theme.paddingMedium)

            Text("premium.paywall.title".localized)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color("TextPrimary"))
                .multilineTextAlignment(.center)

            Text("premium.paywall.subtitle".localized)
                .font(Theme.bodyFont)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color("PrimaryBlue"))
                        .frame(width: 6, height: 6)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color("TextPrimary"))

                        Text(feature.description)
                            .font(Theme.captionFont)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }
            }
        }
        .padding(Theme.paddingMedium)
        .background(Color("BackgroundLight"))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color("SecondaryBlue").opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var pricingSection: some View {
        HStack(spacing: 12) {
            if let yearly = manager.yearlyProduct {
                pricingCard(
                    product: yearly,
                    label: "premium.yearly".localized,
                    detail: "premium.yearly.per_month".localized(with: manager.yearlyMonthlyEquivalent ?? ""),
                    badge: "premium.yearly.save".localized(with: manager.savingsPercentage),
                    isSelected: selectedProduct?.id == yearly.id
                )
            }

            if let monthly = manager.monthlyProduct {
                pricingCard(
                    product: monthly,
                    label: "premium.monthly".localized,
                    detail: nil,
                    badge: nil,
                    isSelected: selectedProduct?.id == monthly.id
                )
            }
        }
    }

    private func pricingCard(
        product: Product,
        label: String,
        detail: String?,
        badge: String?,
        isSelected: Bool
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                selectedProduct = product
            }
        } label: {
            VStack(spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color("PrimaryBlue"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color("PrimaryBlue").opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(label)
                    .font(Theme.captionFont.weight(.semibold))
                    .foregroundStyle(Color("TextSecondary"))

                Text(product.displayPrice)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("TextPrimary"))

                if let detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Color("TextSecondary"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color("BackgroundLight"))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(isSelected ? Color("PrimaryBlue") : Color("SecondaryBlue").opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var ctaSection: some View {
        VStack(spacing: 10) {
            Button {
                guard let product = selectedProduct else { return }
                Task {
                    isPurchasing = true
                    defer { isPurchasing = false }

                    do {
                        let success = try await manager.purchase(product)
                        if success { dismiss() }
                    } catch {
                        errorText = error.localizedDescription
                        showError = true
                    }
                }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("premium.start".localized)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color("PrimaryBlue"), Color("SecondaryBlue")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .disabled(selectedProduct == nil || isPurchasing)

            if isTrialEligible {
                Text("premium.trial".localized)
                    .font(Theme.captionFont.weight(.medium))
                    .foregroundStyle(Color("PrimaryBlue"))
            }

            Text("premium.cancel_anytime".localized)
                .font(.system(size: 11))
                .foregroundStyle(Color("TextSecondary"))
        }
    }

    private var legalSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await manager.restore() }
            } label: {
                Text("premium.restore".localized)
                    .font(Theme.bodyFont.weight(.medium))
                    .foregroundStyle(Color("TextPrimary"))
            }

            HStack(spacing: 16) {
                Link("premium.terms".localized, destination: URL(string: "https://lifeanalytics.app/terms")!)
                    .font(.system(size: 11))
                    .foregroundStyle(Color("TextSecondary"))

                Link("premium.privacy".localized, destination: URL(string: "https://lifeanalytics.app/privacy")!)
                    .font(.system(size: 11))
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
    }
}
