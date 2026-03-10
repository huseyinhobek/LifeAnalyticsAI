# LIFE ANALYTICS AI — UYGULAMA İÇİ SATIN ALMA (IN-APP PURCHASE)
# Bu promptu OpenAI Codex / Claude Code / Cursor'a ver.

---

## CONTEXT

LifeAnalyticsAI iOS uygulaması. Swift 5.9+ / SwiftUI / iOS 17.0+ / Clean Architecture.
Proje LAI-110'a kadar tamamlandı. Proxy çalışıyor. Lokalizasyon (TR/EN) eklendi.

Görev: StoreKit 2 ile uygulama içi satın alma sistemi kur.

Fiyatlandırma:
- Premium Aylık: $7.99/ay (Product ID: com.lifeanalytics.premium.monthly)
- Premium Yıllık: $49.99/yıl (Product ID: com.lifeanalytics.premium.yearly)
- 1 hafta ücretsiz deneme (her iki planda)

Free vs Premium:
- FREE: Ruh hali kaydı (sınırsız), uyku verisi görüntüleme, takvim entegrasyonu, basit grafikler (7 gün), günde 1 AI içgörü
- PREMIUM: Sınırsız AI içgörü, haftalık AI raporu, çapraz korelasyon, öngörüsel tahminler, 90 gün+ trend, tam içgörü geçmişi, veri dışa aktarma

---

## DOSYA 1 — AppConstants.swift'e Ekle

Mevcut AppConstants enum'ına şunu ekle:

```swift
enum Subscription {
    static let groupID = "premium_group"
    static let monthlyID = "com.lifeanalytics.premium.monthly"
    static let yearlyID = "com.lifeanalytics.premium.yearly"
    static let allProductIDs: Set<String> = [monthlyID, yearlyID]
    static let freeInsightsPerDay = 1
    static let freeInsightHistoryLimit = 3
    static let freeChartDaysLimit = 7
}
```

---

## DOSYA 2 — Domain/Models/PremiumFeature.swift (YENİ)

```swift
import Foundation

enum PremiumFeature: String, CaseIterable {
    case unlimitedInsights
    case weeklyReport
    case crossCorrelation
    case predictions
    case extendedTrends
    case fullInsightHistory
    case dataExport
    case priorityAI

    var displayName: String {
        return "\(rawValue)_title".localized
    }

    var description: String {
        return "\(rawValue)_desc".localized
    }
}
```

---

## DOSYA 3 — Core/Utilities/SubscriptionManager.swift (YENİ)

```swift
import StoreKit
import OSLog

@Observable
class SubscriptionManager {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Subscription")

    var products: [Product] = []
    var isPremium: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    var monthlyProduct: Product? {
        products.first { $0.id == AppConstants.Subscription.monthlyID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == AppConstants.Subscription.yearlyID }
    }

    var yearlyMonthlyEquivalent: String? {
        guard let yearly = yearlyProduct else { return nil }
        let monthly = yearly.price / 12
        return yearly.priceFormatStyle.format(monthly)
    }

    var savingsPercentage: Int {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return 0 }
        let yearlyTotal = yearly.price
        let monthlyTotal = monthly.price * 12
        guard monthlyTotal > 0 else { return 0 }
        return Int(((monthlyTotal - yearlyTotal) / monthlyTotal * 100).rounded())
    }

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            products = try await Product.products(for: AppConstants.Subscription.allProductIDs)
                .sorted { $0.price < $1.price }
            logger.info("Loaded \(self.products.count) products")
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            await MainActor.run { errorMessage = "error.products_load".localized }
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
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

    // MARK: - Restore

    @MainActor
    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            logger.info("Restore completed. isPremium: \(self.isPremium)")
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            errorMessage = "error.restore_failed".localized
        }
    }

    // MARK: - Status

    func updateSubscriptionStatus() async {
        var hasActive = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if AppConstants.Subscription.allProductIDs.contains(transaction.productID) {
                    if transaction.revocationDate == nil && !transaction.isUpgraded {
                        hasActive = true
                    }
                }
            }
        }

        await MainActor.run {
            self.isPremium = hasActive
            logger.info("Subscription status updated. isPremium: \(hasActive)")
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.updateSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Feature Access

    func hasAccess(to feature: PremiumFeature) -> Bool {
        return isPremium
    }

    // MARK: - Daily Insight Counter

    var dailyInsightsRemaining: Int {
        if isPremium { return 999 }
        let key = dailyCounterKey
        let used = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite)?
            .integer(forKey: key) ?? 0
        return max(0, AppConstants.Subscription.freeInsightsPerDay - used)
    }

    func recordInsightUsage() {
        guard !isPremium else { return }
        let key = dailyCounterKey
        let defaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite)!
        let current = defaults.integer(forKey: key)
        defaults.set(current + 1, forKey: key)
    }

    private var dailyCounterKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "insights_used_\(formatter.string(from: Date()))"
    }

    // MARK: - Trial Eligibility

    func isEligibleForTrial() async -> Bool {
        for product in products {
            if let subscription = product.subscription {
                return await subscription.isEligibleForIntroOffer
            }
        }
        return false
    }
}

enum SubscriptionError: LocalizedError {
    case verificationFailed
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "error.verification_failed".localized
        case .purchaseFailed: return "error.purchase_failed".localized
        }
    }
}
```

---

## DOSYA 4 — Presentation/Components/PremiumGate.swift (YENİ)

```swift
import SwiftUI

struct PremiumGate: ViewModifier {
    @Environment(SubscriptionManager.self) var subscriptionManager
    let feature: PremiumFeature
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if subscriptionManager.hasAccess(to: feature) {
            content
        } else {
            content
                .blur(radius: 8)
                .allowsHitTesting(false)
                .overlay {
                    lockedOverlay
                }
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
                        colors: [Color("PrimaryBlue"), Color("PrimaryBlue").opacity(0.4)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: 36, height: 3)

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
                            colors: [Color("PrimaryBlue"), .purple.opacity(0.7)],
                            startPoint: .leading, endPoint: .trailing
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
```

---

## DOSYA 5 — Presentation/Screens/Paywall/PaywallView.swift (YENİ)

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionManager.self) var manager
    @Environment(\.dismiss) var dismiss
    @State private var selectedProduct: Product?
    @State private var isTrialEligible = false
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    featuresSection
                    pricingSection
                    ctaSection
                    legalSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color("BackgroundPrimary"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color("TextSecondary"))
                            .padding(8)
                            .background(Color("SurfaceLight"))
                            .clipShape(Circle())
                    }
                }
            }
            .task {
                isTrialEligible = await manager.isEligibleForTrial()
                selectedProduct = manager.yearlyProduct // Yıllık default seçili
            }
            .alert("error.purchase_title".localized, isPresented: $showError) {
                Button("error.ok".localized, role: .cancel) {}
            } message: {
                Text(errorText)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color("PrimaryBlue"), .purple.opacity(0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 16, height: 16)
                }
                .padding(.top, 20)

            Text("premium.paywall.title".localized)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color("TextPrimary"))
                .multilineTextAlignment(.center)

            Text("premium.paywall.subtitle".localized)
                .font(.system(size: 14))
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 28)
    }

    // MARK: - Features

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
                            .font(.system(size: 12))
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }
            }
        }
        .padding(20)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("Border"), lineWidth: 1))
        .padding(.bottom, 24)
    }

    // MARK: - Pricing Cards

    private var pricingSection: some View {
        HStack(spacing: 12) {
            // Yıllık (Önerilen)
            if let yearly = manager.yearlyProduct {
                pricingCard(
                    product: yearly,
                    label: "premium.yearly".localized,
                    detail: "premium.yearly.per_month".localized(with: manager.yearlyMonthlyEquivalent ?? ""),
                    badge: "premium.yearly.save".localized(with: manager.savingsPercentage),
                    isRecommended: true,
                    isSelected: selectedProduct?.id == yearly.id
                )
            }

            // Aylık
            if let monthly = manager.monthlyProduct {
                pricingCard(
                    product: monthly,
                    label: "premium.monthly".localized,
                    detail: nil,
                    badge: nil,
                    isRecommended: false,
                    isSelected: selectedProduct?.id == monthly.id
                )
            }
        }
        .padding(.bottom, 20)
    }

    private func pricingCard(
        product: Product,
        label: String,
        detail: String?,
        badge: String?,
        isRecommended: Bool,
        isSelected: Bool
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
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
                        .background(Color("PrimaryBlue").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("TextSecondary"))

                Text(product.displayPrice)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color("TextPrimary"))

                if let detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Color("TextFaint"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color("PrimaryBlue") : Color("Border"),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }

    // MARK: - CTA

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
                        ProgressView()
                            .tint(.white)
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
                        colors: [Color("PrimaryBlue"), .purple.opacity(0.7)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(selectedProduct == nil || isPurchasing)

            if isTrialEligible {
                Text("premium.trial".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color("PrimaryBlue"))
            }

            Text("premium.cancel_anytime".localized)
                .font(.system(size: 11))
                .foregroundStyle(Color("TextFaint"))
        }
        .padding(.bottom, 20)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await manager.restore() }
            } label: {
                Text("premium.restore".localized)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("TextSecondary"))
            }

            HStack(spacing: 16) {
                Link("premium.terms".localized, destination: URL(string: "https://lifeanalytics.app/terms")!)
                    .font(.system(size: 11))
                    .foregroundStyle(Color("TextFaint"))
                Link("premium.privacy".localized, destination: URL(string: "https://lifeanalytics.app/privacy")!)
                    .font(.system(size: 11))
                    .foregroundStyle(Color("TextFaint"))
            }
        }
    }
}
```

---

## DOSYA 6 — StoreKit Configuration File

Xcode'da File > New > File > StoreKit Configuration File oluştur.
İsim: LifeAnalyticsProducts.storekit

İçine 2 Auto-Renewable Subscription ekle (Subscription Group: Life Analytics Premium):

Product 1:
- Product ID: com.lifeanalytics.premium.monthly
- Reference Name: Premium Monthly
- Price: 7.99
- Duration: 1 Month
- Introductory Offer: Free Trial, 1 Week

Product 2:
- Product ID: com.lifeanalytics.premium.yearly
- Price: 49.99
- Duration: 1 Year
- Introductory Offer: Free Trial, 1 Week

Scheme ayarı: Edit Scheme > Run > Options > StoreKit Configuration > LifeAnalyticsProducts.storekit

---

## DOSYA 7 — Mevcut Dosya Güncellemeleri

### 7a) LifeAnalyticsAIApp.swift — SubscriptionManager inject et:

```swift
@State private var subscriptionManager = SubscriptionManager()

// body içinde ContentView'a ekle:
.environment(subscriptionManager)
```

### 7b) DependencyContainer.swift — ekle:

```swift
lazy var subscriptionManager = SubscriptionManager()
```

### 7c) Premium Gate'leri uygula — şu View'lara .premiumGate() ekle:

- WeeklyReportView içeriği → `.premiumGate(.weeklyReport)`
- Çapraz korelasyon grafikleri → `.premiumGate(.crossCorrelation)`
- Tahmin kartları → `.premiumGate(.predictions)`
- 90 gün+ trend grafikleri → `.premiumGate(.extendedTrends)`
- Insight geçmişinde 4. item'dan itibaren → `.premiumGate(.fullInsightHistory)`
- Export butonu → `.premiumGate(.dataExport)`

DİKKAT: Şu ekranlara gate KOYMA (bunlar free):
- Home ekranı (ana akış)
- Mood giriş ekranı
- Basit grafikler (son 7 gün)
- Günlük 1 AI içgörü kartı
- Settings ekranı
- Onboarding

### 7d) Insight üretim kodunda daily limit ekle:

```swift
// Insight üretmeden önce kontrol:
guard subscriptionManager.isPremium || subscriptionManager.dailyInsightsRemaining > 0 else {
    // Paywall göster veya "Bugünün ücretsiz içgörüsü kullanıldı" mesajı
    return
}

// Üretimden sonra sayacı güncelle:
subscriptionManager.recordInsightUsage()
```

### 7e) SettingsView.swift — Premium bölümü ekle (listenin en üstüne):

```swift
@State private var showPaywall = false
@Environment(SubscriptionManager.self) var subscriptionManager

// List içinde ilk section:
Section {
    if subscriptionManager.isPremium {
        VStack(alignment: .leading, spacing: 6) {
            Text("premium.active".localized)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color("PrimaryBlue"))
            Button("premium.manage".localized) {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 13))
        }
    } else {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Text("premium_unlock_button".localized)
                    .foregroundStyle(Color("PrimaryBlue"))
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(subscriptionManager.dailyInsightsRemaining) " + "premium.insights_remaining".localized)
                    .font(.system(size: 12))
                    .foregroundStyle(Color("TextFaint"))
            }
        }
    }
}
.sheet(isPresented: $showPaywall) {
    PaywallView()
}
```

---

## DOSYA 8 — Localizable.strings Eklemeleri

### tr.lproj/Localizable.strings'e ekle:

```
"premium.paywall.title" = "Yaşamınızı Derinlemesine Anlayın";
"premium.paywall.subtitle" = "AI destekli patern analizi, haftalık raporlar ve öngörüsel içgörüler.";
"premium.monthly" = "Aylık";
"premium.yearly" = "Yıllık";
"premium.yearly.save" = "%%%d tasarruf";
"premium.yearly.per_month" = "aylık %@";
"premium.start" = "Premium Başla";
"premium.trial" = "İlk hafta ücretsiz dene";
"premium.cancel_anytime" = "İstediğin zaman iptal et.";
"premium.restore" = "Satın Almaları Geri Yükle";
"premium.active" = "Premium Aktif";
"premium.manage" = "Aboneliği Yönet";
"premium.terms" = "Kullanım Koşulları";
"premium.privacy" = "Gizlilik Politikası";
"premium_unlock_description" = "Bu özellik Premium abonelik gerektirir.";
"premium_unlock_button" = "Premium'a Geç";
"premium.free_insight_used" = "Bugünün ücretsiz içgörüsü kullanıldı";
"premium.insights_remaining" = "içgörü hakkı kaldı";
"error.purchase_title" = "Satın Alma Hatası";
"error.verification_failed" = "Satın alma doğrulanamadı.";
"error.purchase_failed" = "Satın alma başarısız oldu.";
"error.restore_failed" = "Geri yükleme başarısız.";
"error.products_load" = "Ürünler yüklenemedi.";
"unlimitedInsights_title" = "Sınırsız AI İçgörü";
"unlimitedInsights_desc" = "Günlük limit olmadan tüm içgörülere eriş";
"weeklyReport_title" = "Haftalık AI Raporu";
"weeklyReport_desc" = "Her hafta kişisel yaşam analizi";
"crossCorrelation_title" = "Çapraz Korelasyon";
"crossCorrelation_desc" = "Uyku, ruh hali ve takvim arası bağlantılar";
"predictions_title" = "Öngörüsel Tahminler";
"predictions_desc" = "Yarın ve gelecek hafta için AI öngörüleri";
"extendedTrends_title" = "Uzun Vadeli Trendler";
"extendedTrends_desc" = "90 gün ve yıllık trend analizleri";
"fullInsightHistory_title" = "Tam Geçmiş";
"fullInsightHistory_desc" = "Tüm keşiflerin kronolojik arşivi";
"dataExport_title" = "Veri Dışa Aktarma";
"dataExport_desc" = "CSV ve PDF olarak verilerini indir";
"priorityAI_title" = "Öncelikli AI";
"priorityAI_desc" = "Daha hızlı AI yanıt süresi";
```

### en.lproj/Localizable.strings'e aynı key'lerin İngilizce karşılıklarını ekle.

---

## KRİTİK KURALLAR

1. StoreKit 2 kullan (StoreKit 1 değil). async/await API.
2. Fiyatları HARDCODE etme — Product.displayPrice kullan (Apple lokalize eder).
3. Receipt validation manuel yapma — StoreKit 2 otomatik JWS verification yapıyor.
4. Free içeriğe gate KOYMA — home, mood girişi, basit grafikler, 1 günlük insight HER ZAMAN açık.
5. PaywallView'da emoji ve ikon KULLANMA — tipografi ve renk ile vurgu yap.
6. Transaction.updates listener'ı MUTLAKA ekle — arka plan yenilemeleri için.
7. Restore butonu MUTLAKA olmalı — App Store review reddi nedeni.

---

## DOĞRULAMA

1. Cmd+B — hatasız build
2. Scheme > StoreKit config seçili olmalı
3. Simulator'de: 2 ürün yüklenmeli (products.count == 2)
4. Free modda: 1 insight sonra limit, premium gate'ler aktif
5. Satın alma: paywall → ürün seç → satın al → gate'ler kalkar
6. Restore: uygulama sil-yükle → geri yükle → premium aktif
7. Projede "7.99" veya "49.99" hardcode araması → SIFIR sonuç (fiyat Product'tan gelmeli)
