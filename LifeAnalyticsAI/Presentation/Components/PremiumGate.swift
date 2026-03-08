// MARK: - Presentation.Components

import SwiftUI

struct PremiumGate: ViewModifier {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    let feature: PremiumFeature
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if subscriptionManager.hasAccess(to: feature) {
            content
        } else {
            content
                .blur(radius: 8)
                .allowsHitTesting(false)
                .overlay { lockedOverlay }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
        }
    }

    private var lockedOverlay: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color("PrimaryBlue"), Color("SecondaryBlue")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 40, height: 4)

            Text(feature.displayName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("TextPrimary"))

            Text("premium_unlock_description".localized)
                .font(.system(size: 13))
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button {
                showPaywall = true
            } label: {
                Text("premium_unlock_button".localized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color("PrimaryBlue"), Color("SecondaryBlue")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(28)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(16)
    }
}

extension View {
    func premiumGate(_ feature: PremiumFeature) -> some View {
        modifier(PremiumGate(feature: feature))
    }
}
