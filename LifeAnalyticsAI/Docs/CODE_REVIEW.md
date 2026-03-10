# LifeAnalyticsAI — Kod İnceleme Raporu

> Tarih: 2026-03-10
> Kapsam: `LifeAnalyticsAI/` dizini (testler hariç)
> Toplam tespit: **26 sorun** — 5 Kritik · 7 Uyarı · 14 Minor

---

## İçindekiler

1. [KRİTİK — Crash Riski Taşıyan Sorunlar](#1-kritik)
2. [UYARI — Davranış Hataları ve Riskli Desenler](#2-uyarı)
3. [MİNOR — Kod Kalitesi ve Bakım Sorunları](#3-minor)
4. [Genel Mimari Değerlendirme](#4-genel-mimari-değerlendirme)
5. [Öncelik Sırası ve Aksiyon Planı](#5-öncelik-sırası-ve-aksiyon-planı)

---

## 1. KRİTİK

Bunlar runtime'da crash'e yol açabilecek ya da veri kaybına neden olabilecek sorunlardır.

---

### K-1 · Force Unwrap — AppLogger (7 yer)

**Dosya:** `Core/Utilities/AppLogger.swift` satır 7–13

**Mevcut Kod:**
```swift
enum AppLogger {
    static let health   = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HealthKit")
    static let calendar = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Calendar")
    static let mood     = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Mood")
    static let insight  = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "InsightEngine")
    static let network  = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Network")
    static let ui       = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI")
    static let notification = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Notification")
}
```

**Sorun:**
`Bundle.main.bundleIdentifier` teorik olarak `nil` dönebilen bir optional'dır. `!` ile force-unwrap edildiğinde nil gelirse uygulama anında crash yapar. `AppLogger` static stored property olduğu için uygulama başlangıcında (ilk erişimde) değerlendirilir — yani crash startup anında olur, hata loglanamaz.

**Neden Tehlikeli:**
Test ortamlarında, bazı SwiftUI Preview'larda ya da bundle'ın henüz yüklenip yüklenmediğinden emin olunamayan durumlar özellikle risklidir.

**Düzeltme:**
```swift
private static let subsystem = Bundle.main.bundleIdentifier ?? "com.lifeanalytics.app"

static let health   = Logger(subsystem: subsystem, category: "HealthKit")
static let calendar = Logger(subsystem: subsystem, category: "Calendar")
// ... diğerleri aynı şekilde
```

---

### K-2 · Force Unwrap — UserDefaults (3 dosya)

**Dosyalar:**
- `Core/Utilities/UserDefaultsManager.swift` satır 8
- `Core/Utilities/NotificationEngagementTracker.swift` satır 12
- `Core/Utilities/NotificationTimingOptimizer.swift` satır 12

**Mevcut Kod (her üçünde aynı):**
```swift
private static let defaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite)!
```

**Sorun:**
`UserDefaults(suiteName:)` aşağıdaki durumlarda `nil` döner:
- App Group entitlement hatalıysa
- Entitlements dosyası ile App Group ID uyuşmuyorsa
- Simulator'da App Group provision eksikse

Force-unwrap edildiği için nil geldiğinde anında crash. `UserDefaultsManager` `@Observable` olduğu ve uygulama genelinde environment'a inject edildiği için bu crash startup'ta tetiklenir.

**Düzeltme:**
```swift
// UserDefaultsManager.swift
private let defaults: UserDefaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite) ?? .standard

// NotificationEngagementTracker ve NotificationTimingOptimizer için (static context):
private static let defaults: UserDefaults = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite) ?? .standard
```

**Not:** `.standard` fallback kullanıldığında farklı bir suite'e yazılır — bu kabul edilebilir, çünkü crash'ten iyidir. İsteğe bağlı olarak `AppLogger` ile bir uyarı logu eklenebilir.

---

### K-3 · Force Unwrap — HealthKit Tip Oluşturma

**Dosya:** `Data/DataSources/HealthKit/HealthKitService.swift` satır 11–15

**Mevcut Kod:**
```swift
private let readTypes: Set<HKObjectType> = [
    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
    HKObjectType.quantityType(forIdentifier: .stepCount)!,
    HKObjectType.quantityType(forIdentifier: .heartRate)!
]
```

**Sorun:**
`categoryType(forIdentifier:)` ve `quantityType(forIdentifier:)` optional döner. Normalde iOS 16+ için bu identifierlar geçerlidir; ancak:
- Apple gelecekte bir identifier'ı deprecated edebilir
- Testlerde veya mock ortamında beklenmedik nil gelebilir
- Static stored property olduğu için sınıf yüklendiğinde hemen değerlendirilir

**Ayrıca dikkat:**
Aşağıdaki satırda `fetchSleepData` içinde ise guard kullanılmış (satır 33) — aynı identifier için iki farklı yaklaşım var, tutarsızlık.

```swift
// satır 33 — guard kullanılmış (doğru):
guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
    throw AppError.dataNotFound
}

// satır 12 — force-unwrap (yanlış):
HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
```

**Düzeltme:**
```swift
private let readTypes: Set<HKObjectType> = {
    var types = Set<HKObjectType>()
    if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)   { types.insert(sleep) }
    if let steps = HKObjectType.quantityType(forIdentifier: .stepCount)        { types.insert(steps) }
    if let heart = HKObjectType.quantityType(forIdentifier: .heartRate)        { types.insert(heart) }
    return types
}()
```

---

### K-4 · fatalError — PersistenceController (Recovery Yok)

**Dosya:** `Data/Persistence/PersistenceController.swift` satır 30–32

**Mevcut Kod:**
```swift
do {
    container = try ModelContainer(for: schema, configurations: [config])
    // ...
} catch {
    fatalError("ModelContainer olusturulamadi: \(error.localizedDescription)")
}
```

**Sorun:**
`ModelContainer` başlatılamazsa (disk dolu, SwiftData şema uyuşmazlığı, migration hatası vb.) uygulama `fatalError` ile tamamen crash yapar. Kullanıcıya hiçbir şey gösterilmez. Bu gerçek cihazlarda da yaşanabilir, özellikle:
- App güncellendikten sonra şema değiştiyse
- Cihaz depolama alanı sıfıra düştüyse
- Dosya sistemi erişim hatası olduysa

**Recovery Yolu Yok:**
`fatalError` kullanıldığında hem kullanıcıya mesaj gösterilemez hem de in-memory fallback'e geçilemez.

**Düzeltme Yaklaşımı:**
```swift
init(inMemory: Bool = false) {
    // ...
    do {
        container = try ModelContainer(for: schema, configurations: [config])
        // ...
    } catch {
        // Şema değişti — mevcut store'u sil ve yeniden dene
        AppLogger.insight.error("ModelContainer failed, attempting recovery: \(error)")
        do {
            // İlk deneme başarısız olduysa in-memory fallback
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: schema, configurations: [fallbackConfig])
            AppLogger.insight.warning("Running with in-memory store — data will not persist")
        } catch {
            // Artık burada fatalError kabul edilebilir, çünkü in-memory bile başarısız
            fatalError("ModelContainer tamamen başlatılamadı: \(error)")
        }
    }
}
```

---

### K-5 · Force Unwrap — Widget URL

**Dosya:** `Widgets/QuickMoodWidget.swift` satır 62–64

**Mevcut Kod:**
```swift
private func quickMoodURL(value: Int) -> URL {
    URL(string: "lifeanalytics://mood-entry?preset=\(value)")
        ?? URL(string: "lifeanalytics://mood-entry")!  // ← CRASH
}
```

**Sorun:**
İlk URL oluşturma başarısız olursa (değer özel karakter içerirse vs.) fallback'e düşülür ve fallback da force-unwrap edilir. `value` bir `Int` olduğu için normalde güvenlidir; ama ikinci URL de hatalı olursa crash.

**Düzeltme:**
```swift
private func quickMoodURL(value: Int) -> URL {
    // Int'ten gelen değer URL-safe, bu yüzden ilk seçenek her zaman geçerli
    // ama force-unwrap yerine sabit bir fallback kullanalım
    URL(string: "lifeanalytics://mood-entry?preset=\(value)")
        ?? URL(string: "lifeanalytics://mood-entry")
        ?? URL(fileURLWithPath: "/")  // asla null olmayacak fallback
}
```

---

## 2. UYARI

Bunlar crash yaratmaz ancak yanlış davranışa, veri tutarsızlığına veya memory sorunlarına yol açabilir.

---

### U-1 · Task Leak — ProxyHealthChecker

**Dosya:** `Core/Utilities/ProxyHealthChecker.swift` satır 31–38

**Mevcut Kod:**
```swift
func startPeriodicCheck(interval: TimeInterval = 300) {
    Task {           // ← Task referansı saklanmıyor
        while !Task.isCancelled {
            await performHealthCheck()
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }
}
```

**Sorun:**
1. `Task` oluşturulup dönen değer hiçbir yere atanmıyor — bu task hiçbir zaman iptal edilemiyor.
2. `startPeriodicCheck` her çağrıldığında yeni bir task oluşturuyor — birden fazla kez çağrılırsa aynı anda çalışan birden fazla health checker task oluşur.
3. `ProxyHealthChecker.shared` singleton olduğu için bu tasklar process ölene kadar çalışmaya devam eder (memory leak değil ama kaynak israfı).
4. `Task.isCancelled` doğru kontrol ediliyor ancak task dışarıdan iptal edilemediği için bu kontrol hiçbir zaman `true` olmaz.

**Düzeltme:**
```swift
@Observable
final class ProxyHealthChecker {
    // ...
    private var periodicTask: Task<Void, Never>?

    func startPeriodicCheck(interval: TimeInterval = 300) {
        // Önceki task'ı iptal et
        periodicTask?.cancel()

        periodicTask = Task {
            while !Task.isCancelled {
                await performHealthCheck()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    func stopPeriodicCheck() {
        periodicTask?.cancel()
        periodicTask = nil
    }
}
```

---

### U-2 · Hardcoded Türkçe String'ler — PatternInsightEngine

**Dosya:** `Data/DataSources/Insights/PatternInsightEngine.swift`

**Sorun:**
Kullanıcıya gösterilecek insight metinleri doğrudan Swift koduna Türkçe olarak yazılmış. Uygulama İngilizce kullanıcılara da hizmet ediyorsa ya da ilerleyen dönemde dil desteği eklenirse bu metinler çevrilemez.

**Mevcut Kod:**
```swift
// satır 55–56
title: "Kaynaklar arasi iliski bulundu",
body: "\(score.lhsMetric.rawValue) ve \(score.rhsMetric.rawValue) arasinda anlamli bir iliski goruldu.",

// satır 80–81
title: "Beklenmeyen degisim tespit edildi",
body: "\(anomaly.metric.rawValue) degeri kisinin normal araligindan saptı (z=\(String(format: "%.2f", anomaly.zScore))).",

// satır 99–100
title: "Haftalik dongu paterni bulundu",
body: "Hafta sonu etkisi \(String(format: "%.2f", seasonality.weekendEffect)), Monday sendromu gucu \(String(format: "%.2f", seasonality.mondaySyndromeStrength)).",

// satır 143
predictionText = "Yarin icin tahmini mood: \(String(format: "%.2f", prediction.predictedMoodNextDay))"

// satır 151
summary: "Pattern Engine haftalik ozeti olusturuldu.",
```

**Ayrıca aynı dosyada İngilizce unit string'leri de var (satır 60, 84):**
```swift
unit: "effect"   // İngilizce
unit: "orneklem" // Türkçe
unit: "ham"      // Türkçe
unit: "puan"     // Türkçe
unit: "saat"     // Türkçe
```

**Düzeltme:**
Tüm kullanıcıya görünen string'leri `Localizable.strings` (veya `.xcstrings`) dosyasına taşı:
```swift
title: "insight.correlation.title".localized,
body: String(format: "insight.correlation.body".localized, score.lhsMetric.rawValue, score.rhsMetric.rawValue),
```

**Not:** `QuickMoodWidget.swift` satır 38 ve 54'te de aynı sorun var:
```swift
Text("Hizli Mood Girisi")  // satır 38 — hardcoded
Text("Secim uygulamada mood ekranini acar")  // satır 54 — hardcoded
```

---

### U-3 · String Index — Güvensiz Offset

**Dosya:** `Domain/UseCases/GenerateDailyInsightCardUseCase.swift` satır 53–58

**Mevcut Kod:**
```swift
if trimmed.count <= 160 {
    return trimmed
}

let endIndex = trimmed.index(trimmed.startIndex, offsetBy: 157)
return String(trimmed[..<endIndex]) + "..."
```

**Sorun:**
`trimmed.count <= 160` kontrolü geçildiğinde `trimmed.count > 160` olduğu garantilenir. Yani `offsetBy: 157` normalde güvenlidir. **Ancak:** `trimmed.count` karakter sayısını döner, `String.Index` ise Unicode grapheme cluster'larla çalışır. Emoji veya birleşik Unicode karakterler içeren metinlerde `count` ve `index(_:offsetBy:)` farklı davranabilir — her iki durumda da `offsetBy: 157` güvenlidir ama Apple, ileride bu davranışı değiştirebilir.

Daha önemli bir sorun: eğer `shortCardMessage` dışından doğrudan çağrılabilecek şekilde değiştirilirse kontrol kaldırılabilir ve crash riski oluşur.

**Düzeltme:**
```swift
let safeOffset = min(157, trimmed.count)
let endIndex = trimmed.index(trimmed.startIndex, offsetBy: safeOffset)
return String(trimmed[..<endIndex]) + "..."
```

---

### U-4 · Bootstrap Retry Yok — InsightHistoryViewModel

**Dosya:** `Presentation/ViewModels/InsightHistoryViewModel.swift` satır 17, 39–42

**Mevcut Kod:**
```swift
private var hasAttemptedBootstrapGeneration = false

// refresh() içinde:
if fetchedInsights.isEmpty && !hasAttemptedBootstrapGeneration {
    hasAttemptedBootstrapGeneration = true
    _ = try await generateInsightUseCase.execute()
    fetchedInsights = try await repository.fetchInsights(limit: 200)
}
```

**Sorun:**
`hasAttemptedBootstrapGeneration = true` atama işlemi, generate işlemi başlamadan önce yapılıyor. Eğer `generateInsightUseCase.execute()` hata fırlatırsa (`catch` bloğuna düşülür), bayrak zaten `true` olduğu için bir sonraki `refresh()` çağrısında yeniden deneme yapılmaz. Kullanıcı listeyi pull-to-refresh yapsa bile yeniden generate edilmez.

**Senaryo:**
1. Kullanıcı ilk kez Insights ekranını açar
2. Ağ bağlantısı yoktur, `execute()` hata fırlatır
3. `hasAttemptedBootstrapGeneration = true` olmuş durumda
4. Kullanıcı ağa bağlanır ve refresh yapar
5. Bayrak `true` olduğu için yeniden denenmez — kullanıcı boş ekran görür

**Düzeltme:**
```swift
if fetchedInsights.isEmpty && !hasAttemptedBootstrapGeneration {
    hasAttemptedBootstrapGeneration = true
    do {
        _ = try await generateInsightUseCase.execute()
        fetchedInsights = try await repository.fetchInsights(limit: 200)
    } catch {
        // Başarısız olursa bayrağı sıfırla, bir sonraki refresh'te tekrar deneyebilsin
        hasAttemptedBootstrapGeneration = false
        throw error  // üst catch'e ilet
    }
}
```

---

### U-5 · Force Unwrap URL — PaywallView

**Dosya:** `Presentation/Screens/Paywall/PaywallView.swift` satır 247, 251

**Mevcut Kod:**
```swift
Link("premium.terms".localized, destination: URL(string: "https://lifeanalytics.app/terms")!)
Link("premium.privacy".localized, destination: URL(string: "https://lifeanalytics.app/privacy")!)
```

**Sorun:**
URL string'leri hardcoded ve geçerli görünüyor, bu nedenle pratikte crash riski düşük. Ama yine de force-unwrap kötü pratik. Daha önemlisi: bu URL'ler `AppConstants` içinde tanımlanmamış — domain değiştiğinde tek tek aramak gerekir.

**Düzeltme:**
URL'leri `AppConstants` içine taşı ve güvenli oluştur:
```swift
// AppConstants içine ekle:
enum URLs {
    static let terms   = URL(string: "https://lifeanalytics.app/terms")
    static let privacy = URL(string: "https://lifeanalytics.app/privacy")
}

// PaywallView içinde:
if let termsURL = AppConstants.URLs.terms {
    Link("premium.terms".localized, destination: termsURL)
}
```

---

### U-6 · Ham Token Tahmini — AnthropicLLMService

**Dosya:** `Data/DataSources/AI/AnthropicLLMService.swift` satır 106–109

**Mevcut Kod:**
```swift
private func estimateTokens(_ text: String) -> Int {
    guard !text.isEmpty else { return 1 }
    return max(1, text.count / 4)
}
```

**Sorun:**
`text.count / 4` kuralı yalnızca İngilizce ASCII metinler için makul bir tahmindir. Türkçe karakterler (ş, ğ, ü, ö, ç, ı) ve özellikle Arapça, Çince gibi diller için token başına karakter sayısı çok farklıdır. Anthropic'in tokenizasyonunda Türkçe metin genellikle daha fazla token tüketir.

**Pratik Sonuç:**
Bütçe kontrolü (`canConsume`) gerçeğin altında token tahmini yapacağı için günlük token limiti beklenenden daha hızlı tükenir ve kullanıcılar erken kilitlenebilir. Ya da tam tersi — limit aşımı tespit edilemez.

**Düzeltme:**
Dil farkındalıklı bir çarpan kullan:
```swift
private func estimateTokens(_ text: String) -> Int {
    guard !text.isEmpty else { return 1 }
    // ASCII karakterler için ~4 karakter/token,
    // Türkçe/diğer UTF-8 için ~2.5 karakter/token (güvenli taraf)
    let hasNonASCII = text.unicodeScalars.contains { $0.value > 127 }
    let charsPerToken: Double = hasNonASCII ? 2.5 : 4.0
    return max(1, Int(Double(text.count) / charsPerToken))
}
```

---

### U-7 · Hardcoded Error String — AnthropicLLMService

**Dosya:** `Data/DataSources/AI/AnthropicLLMService.swift` satır 84, 89

**Mevcut Kod:**
```swift
throw AppError.llmError(message: "LLM saatlik istek limiti asildi")
throw AppError.llmError(message: "LLM token limiti asildi")
```

**Sorun:**
Bu hata mesajları kullanıcıya gösterilmek üzere tasarlanmış (`localizedDescription` üzerinden) ve Türkçe hardcoded. Lokalizasyon anahtarı kullanılmalı.

**Düzeltme:**
```swift
throw AppError.llmError(message: "error.llm.rate_limit_exceeded".localized)
throw AppError.llmError(message: "error.llm.token_limit_exceeded".localized)
```

---

## 3. MİNOR

Bunlar acil düzeltme gerektirmez ancak uzun vadede bakım yükünü artırır.

---

### M-1 · Dead Code — calculateHeartRateStats

**Dosya:** `Data/DataSources/HealthKit/HealthKitService.swift` satır 174

**Mevcut Kod:**
```swift
_ = calculateHeartRateStats(from: orderedReadings)
return orderedReadings
```

**Sorun:**
`calculateHeartRateStats` çağrılıyor ancak dönen değer `_` ile atılıyor. Fonksiyon tamamen dead code durumunda.

**Düzeltme:**
Fonksiyon şu an kullanılmıyorsa ya çağrıyı sil ya da dönüş değerini gerçekten kullan.

---

### M-2 · DRY İhlali — JSON Encode/Decode Tekrarı

**Dosyalar:**
- `Data/Persistence/InsightEntity.swift` — `encodeMetrics`, `decodeMetrics` (satır 67–81)
- `Data/Persistence/InsightEntity.swift` — `WeeklyReportEntity` içinde aynı `encodeMetrics`, `decodeMetrics` (satır 151–165) + `encodeInsights`, `decodeInsights`
- `Data/Repositories/InsightRepository.swift` — yine `encodeMetrics` (satır 65–71)

**Sorun:**
`encodeMetrics` fonksiyonu en az 3 farklı yerde aynı şekilde tanımlanmış. Kod değiştiğinde 3 yeri birden güncellemek gerekiyor.

**Düzeltme:**
Bir yerde tanımla:
```swift
// Data/Persistence/JSONCoding+Extensions.swift
extension JSONEncoder {
    static func encodeToString<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }
}

extension JSONDecoder {
    static func decodeFromString<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
```

---

### M-3 · Pagination Eksikliği — InsightRepository

**Dosya:** `Data/Repositories/InsightRepository.swift` satır 37–41

**Mevcut Kod:**
```swift
func fetchInsights(limit: Int) async throws -> [Insight] {
    var descriptor = FetchDescriptor<InsightEntity>(
        sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    descriptor.fetchLimit = max(limit, 0)
    // ...
}
```

**Sorun:**
Çağrı tarafı `limit: 200` sabit bir değer gönderiyor. Gerçek pagination (offset/cursor) desteği yok. Uzun süre kullanılan cihazlarda 200 insight öğesi yetersiz kalabilir. Öte yandan 200 öğeyi tek seferde SwiftData'dan çekmek bellek ve I/O açısından verimsiz.

**Düzeltme:**
Protocol'e offset ekle:
```swift
func fetchInsights(limit: Int, offset: Int) async throws -> [Insight]
// veya SwiftData cursor tabanlı pagination
```

---

### M-4 · Kırılgan Regex — WeeklyReportTextFormatter

**Dosya:** `Core/Utilities/WeeklyReportTextFormatter.swift` satır 24–34

**Mevcut Kod:**
```swift
text = replaceRegex("(?<!\\n)(#{1,2}\\s)", in: text, with: "\n$1")
text = replaceRegex("(?<!\\n)(Hafta:)\\s*", in: text, with: "\n$1 ")
text = replaceRegex("(?<!\\n)(Ozet:|Gozlem:|Oneri:)\\s*", in: text, with: "\n$1 ")
text = replaceRegex("(?m)^Ozet:\\s*", in: text, with: "## Ozet\n")
// ...
```

**Sorun:**
LLM çıktısını regex ile düzeltmeye çalışmak kırılgan bir yaklaşım:
1. LLM prompt değişirse regex'ler işe yaramaz hale gelir
2. Yeni başlıklar eklenirse her birini regex'e eklemek gerekir
3. Negatif lookbehind (`(?<!\\n)`) bazı edge case'lerde yanlış davranabilir
4. `replaceRegex` içindeki `try?` hataları sessizce yutuyor — hatalı bir regex pattern tüm metni değiştirmeden döndürüyor, bu fark edilemez

**Öneri:**
LLM prompt'unu yapılandırılmış çıktı (JSON) döndürecek şekilde güncelle ya da Swift'te basit bir markdown normalizer yaz.

---

### M-5 · Gereksiz Weak Self — AppDelegate

**Dosya:** `App/AppDelegate.swift` (notification observer)

**Sorun:**
`AppDelegate` bir singleton'dır ve uygulama yaşam döngüsü boyunca hayatta kalır. `[weak self]` kullanımı gereksiz ve yanıltıcı — sanki deallocate olabilirmiş gibi görünür.

**Düzeltme:**
`[weak self]` kaldırılabilir ya da yorum eklenebilir.

---

### M-6 · hasAccess Fonksiyonu Anlamsız

**Dosya:** `Core/Utilities/SubscriptionManager.swift` satır 130–133

**Mevcut Kod:**
```swift
func hasAccess(to feature: PremiumFeature) -> Bool {
    _ = feature   // feature parametresi kullanılmıyor
    return isPremium
}
```

**Sorun:**
`feature` parametresi alınıyor ancak kullanılmıyor. Bu fonksiyon `return isPremium` ile eşdeğer. Gelecekte özellik bazlı granüler erişim kontrolü planlanıyorsa bu mantıklı, yoksa şimdiki haliyle yanıltıcı.

**Düzeltme:**
Ya `feature`'ı gerçekten kullan ya da fonksiyonu kaldırıp direkt `isPremium` kullan.

---

### M-7 · DateFormatter Her Çağrıda Yeniden Oluşturuluyor

**Dosya:** `Core/Utilities/SubscriptionManager.swift` satır 176–180

**Mevcut Kod:**
```swift
private var dailyCounterKey: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return "insights_used_\(formatter.string(from: Date()))"
}
```

**Sorun:**
`DateFormatter` pahalı bir nesne — her `dailyCounterKey` erişiminde yeniden oluşturuluyor. `recordInsightUsage()` ve `dailyInsightsRemaining` her çağrıldığında bu oluşturma gerçekleşiyor.

**Düzeltme:**
```swift
private static let dailyKeyFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

private var dailyCounterKey: String {
    "insights_used_\(Self.dailyKeyFormatter.string(from: Date()))"
}
```

---

### M-8 · Magic Numbers — Yaygın

Aşağıdaki dosyalarda açıklaması olmayan magic number'lar kullanılıyor:

| Dosya | Satır | Değer | Açıklama Gereken |
|-------|-------|-------|-----------------|
| `GenerateDailyInsightCardUseCase.swift` | 48, 53, 57 | `160`, `160`, `157` | Max kart uzunluğu |
| `QuickMoodWidget.swift` | 22 | `2` (saat) | Widget refresh aralığı |
| `QuickMoodWidget.swift` | 48 | `32` | Emoji buton min yüksekliği |
| `HealthKitService.swift` | 52 | `12` | Öğle saati bucket sınırı |
| `PatternInsightEngine.swift` | 160 | `30` (gün) | Analiz penceresi |
| `InsightRepository.swift` | 37 | `200` | Limit |

**Düzeltme:** `AppConstants` içine anlamlı isimlerle taşı.

---

### M-9 · İngilizce/Türkçe Karışık Unit String'leri

**Dosya:** `Data/DataSources/Insights/PatternInsightEngine.swift`

```swift
unit: "effect"    // İngilizce
unit: "orneklem"  // Türkçe (ama düzgün yazılmamış)
unit: "ham"       // Türkçe (açıklayıcı değil)
unit: "puan"      // Türkçe
unit: "saat"      // Türkçe
unit: "mood"      // İngilizce
```

Bu unit değerleri UI'da gösteriliyor mu gösterilmiyor mu netleştirilmeli; gösteriliyorsa lokalizasyon anahtarı kullanılmalı.

---

### M-10 · WeeklyReportTextFormatter — Sadece Türkçe Çalışır

**Dosya:** `Core/Utilities/WeeklyReportTextFormatter.swift`

**Sorun:**
`normalizedMarkdown` içindeki string sabitleri tamamen Türkçe:
```swift
("Haftalik OzetHafta:", "# Haftalik Ozet\n\nHafta:"),
("OzetBu", "## Ozet\nBu"),
```
İngilizce LLM çıktısı gelirse bu formatter hiçbir düzeltme yapmaz. Dil algılama veya her iki dil için ayrı pattern seti eklenmeli.

---

### M-11 · Silent JSON Encoding Hataları

**Dosyalar:**
- `Data/Persistence/InsightEntity.swift` satır 67–73
- `Data/Persistence/InsightEntity.swift` satır 151–157
- `Data/Repositories/InsightRepository.swift` satır 65–71

**Mevcut Kod:**
```swift
private static func encodeMetrics(_ metrics: [MetricReference]) -> String {
    guard let data = try? JSONEncoder().encode(metrics),
          let json = String(data: data, encoding: .utf8) else {
        return "[]"   // ← hata sessizce yutuldu
    }
    return json
}
```

**Sorun:**
Encoding başarısız olursa `"[]"` döner — veri kaybı loglanmadan gerçekleşir. Hangi durumda başarısız oldu, neden? Hiçbir iz yok.

**Düzeltme:**
```swift
private static func encodeMetrics(_ metrics: [MetricReference]) -> String {
    do {
        let data = try JSONEncoder().encode(metrics)
        return String(data: data, encoding: .utf8) ?? "[]"
    } catch {
        AppLogger.insight.error("MetricReference JSON encoding failed: \(error)")
        return "[]"
    }
}
```

---

### M-12 · InsightEntity.toDomain — Silent Fallback

**Dosya:** `Data/Persistence/InsightEntity.swift` satır 42–44

**Mevcut Kod:**
```swift
type: Insight.InsightType(rawValue: type) ?? .trend,
// ...
confidenceLevel: Insight.ConfidenceLevel(rawValue: confidenceLevel) ?? .medium,
```

**Sorun:**
Veritabanındaki `type` veya `confidenceLevel` string değeri geçersizse (şema değişimi sonrası olabilir) sessizce `.trend` veya `.medium` döner. Bu yanlış bir insight kategorisiyle gösterime yol açabilir.

**Düzeltme:**
En azından log at:
```swift
let insightType = Insight.InsightType(rawValue: type) ?? {
    AppLogger.insight.warning("Unknown insight type '\(type)', falling back to .trend")
    return Insight.InsightType.trend
}()
```

---

### M-13 · SubscriptionManager.listenForTransactions — Weak Self Gereksiz Risk

**Dosya:** `Core/Utilities/SubscriptionManager.swift` satır 157–164

**Mevcut Kod:**
```swift
private func listenForTransactions() -> Task<Void, Never> {
    Task.detached { [weak self] in
        for await result in Transaction.updates {
            guard case let .verified(transaction) = result else { continue }
            await transaction.finish()
            await self?.updateSubscriptionStatus()  // ← self nil olursa çağrılmaz
        }
    }
}
```

**Sorun:**
`SubscriptionManager` singleton değil — `@Environment` ile inject edilen bir `@Observable` nesne. Teorik olarak deallocate olabilir. Bu durumda transaction update'leri `transaction.finish()` sonrası kayıt altına alınmaz — kullanıcı satın aldı ama premium durumu güncellenemedi.

**Daha Önemli Sorun:**
`transaction.finish()` weak self'e bağlı değil (doğru), ama `updateSubscriptionStatus()` bağlı. `finish()` çağrıldıktan sonra `self` nil ise kullanıcının satın alma işlemi Apple tarafından tamamlandı ancak uygulama premium durumu güncellenmedi.

**Düzeltme:**
`updateSubscriptionStatus()`'ı statik/global bir fonksiyon yap veya `SubscriptionManager`'ı singleton olarak işaretle.

---

### M-14 · Duplicate Channel Mapping — NotificationEngagementTracker ve NotificationTimingOptimizer

**Dosyalar:**
- `Core/Utilities/NotificationEngagementTracker.swift` satır 44–55
- `Core/Utilities/NotificationTimingOptimizer.swift` satır 36–47

**Sorun:**
`channel(for:)` fonksiyonu (categoryIdentifier'dan Channel enum'ına dönüşüm) iki dosyada birebir aynı şekilde tanımlanmış. Yeni bir notification kanalı eklenirse her iki yerde de güncellenmesi gerekir.

**Düzeltme:**
`Channel` enum'ını ortak bir yere taşı ve `init?(categoryIdentifier:)` ekle:
```swift
// Ortak bir dosyada:
extension NotificationChannel {
    init?(categoryIdentifier: String) {
        switch categoryIdentifier {
        case AppConstants.Notifications.Category.morning: self = .morning
        case AppConstants.Notifications.Category.evening: self = .evening
        case AppConstants.Notifications.Category.weekly:  self = .weekly
        default: return nil
        }
    }
}
```

---

## 4. Genel Mimari Değerlendirme

### Güçlü Yönler

- **Protocol-based bağımlılıklar:** Repository'ler, use case'ler ve servisler protocol'ler üzerinden inject ediliyor — test edilebilirlik yüksek.
- **Async/await kullanımı:** Callback'lerden kaçınılmış, modern Swift concurrency doğru kullanılmış.
- **Lokalizasyon tutarlılığı:** UI katmanının büyük bölümünde `.localized` extension'ı kullanılmış.
- **SwiftData entegrasyonu:** `@Model`, `FetchDescriptor` ve `ModelContext` doğru kullanılmış.
- **StoreKit 2:** `Transaction.currentEntitlements` ve `Transaction.updates` modern API'lar kullanılmış.
- **Offline fallback:** LLM servisinde `OfflineFallbackGenerating` ile network olmadan da içerik üretiliyor.
- **Data protection:** `PersistenceController` içinde dosya sistemi koruma özelliği eklenmiş — güvenlik açısından olumlu.

### İyileştirilmesi Gereken Yönler

- **Hata yönetimi tutarsızlığı:** Bazı katmanlarda `try?` ile hatalar yutuluyor, bazılarında throw ediliyor — standart bir hata yönetimi politikası belirlenmeli.
- **Lokalizasyon eksikliği:** Data katmanında (engine, formatter) hardcoded Türkçe string'ler var — lokalizasyon yalnızca Presentation katmanında tamamlanmış.
- **Concurrent SwiftData erişimi:** `InsightRepository` ve diğer repository'ler `@MainActor.run` ile MainActor'da çalışıyor, bu doğru; ancak birden fazla repository aynı anda yazarsa `ModelContext` üzerinde çakışma riski var.

---

## 5. Öncelik Sırası ve Aksiyon Planı

### Sprint 1 — Hemen Yapılmalı (Crash Riski)

| # | Görev | Dosya |
|---|-------|-------|
| 1 | `Bundle.main.bundleIdentifier!` → nil-coalescing | `AppLogger.swift` |
| 2 | `UserDefaults(suiteName:)!` → `.standard` fallback (3 dosya) | `UserDefaultsManager`, `NotificationEngagementTracker`, `NotificationTimingOptimizer` |
| 3 | HealthKit tip force-unwrap → lazy computed set | `HealthKitService.swift` |
| 4 | `fatalError` → in-memory fallback | `PersistenceController.swift` |
| 5 | Widget URL force-unwrap → güvenli fallback | `QuickMoodWidget.swift` |

### Sprint 2 — Kısa Vadeli (Yanlış Davranış)

| # | Görev | Dosya |
|---|-------|-------|
| 6 | ProxyHealthChecker task referansı sakla | `ProxyHealthChecker.swift` |
| 7 | Bootstrap retry flag düzelt | `InsightHistoryViewModel.swift` |
| 8 | Hardcoded URL'leri AppConstants'a taşı | `PaywallView.swift` |
| 9 | Token tahmini dil farkındalıklı hale getir | `AnthropicLLMService.swift` |
| 10 | LLM hata mesajları lokalize et | `AnthropicLLMService.swift` |

### Sprint 3 — Orta Vadeli (Bakım)

| # | Görev | Dosya |
|---|-------|-------|
| 11 | PatternInsightEngine Türkçe string'leri lokalize et | `PatternInsightEngine.swift` |
| 12 | Widget hardcoded Türkçe string'leri lokalize et | `QuickMoodWidget.swift` |
| 13 | JSON encode/decode DRY hale getir | `InsightEntity.swift`, `InsightRepository.swift` |
| 14 | Dead code `calculateHeartRateStats` kaldır | `HealthKitService.swift` |
| 15 | `DateFormatter` static hale getir | `SubscriptionManager.swift` |
| 16 | Silent JSON encoding hatalarını logla | Tüm entity'ler |
| 17 | Channel mapping duplicate kaldır | `NotificationEngagementTracker`, `NotificationTimingOptimizer` |
| 18 | Magic number'ları AppConstants'a taşı | Çeşitli |

---

*Bu rapor otomatik araçlar + manuel kod incelemesi ile hazırlanmıştır. Testler kapsam dışındadır.*
