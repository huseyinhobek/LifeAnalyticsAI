# LIFE ANALYTICS AI — TAM LOKALİZASYON (TÜRKÇE + İNGİLİZCE)
# Bu promptu OpenAI Codex / Claude Code / Cursor'a ver.

---

## CONTEXT (MEVCUT DURUM)

LifeAnalyticsAI adlı bir iOS uygulaması üzerinde çalışıyorsun.
- Swift 5.9+ / SwiftUI / iOS 17.0+
- Clean Architecture (MVVM + Repository + UseCase)
- Proje klasör yapısı: App/, Core/, Domain/, Data/, Presentation/, Resources/
- Proxy üzerinden Claude API kullanılıyor (URL: https://life-analytics-proxy.hsynhbk.workers.dev/v1/insight)
- NetworkManager.swift içinde sendLLMRequest(prompt:systemPrompt:) metodu mevcut

Görev: Uygulamaya tam Türkçe + İngilizce dil desteği ekle. Hem UI metinleri hem AI yanıt dili kullanıcının tercihine göre değişmeli.

---

## ADIM 1 — LanguageManager Oluştur

`Core/Utilities/LanguageManager.swift` dosyası oluştur:

```swift
import Foundation
import SwiftUI

@Observable
class LanguageManager {
    
    enum AppLanguage: String, CaseIterable, Codable {
        case turkish = "tr"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .turkish: return "Türkçe"
            case .english: return "English"
            }
        }
        
        var flag: String {
            switch self {
            case .turkish: return "🇹🇷"
            case .english: return "🇬🇧"
            }
        }
        
        var systemPromptInstruction: String {
            switch self {
            case .turkish:
                return """
                Sen bir kişisel yaşam analisti AI asistansın. 
                Tüm yanıtlarını Türkçe ver. 
                Kullanıcıya "sen" diye hitap et, samimi ama profesyonel bir ton kullan.
                Sayısal verileri metrik sistemde ver (kg, km, saat).
                Tarih formatı: gün.ay.yıl (örn: 7 Mart 2026).
                """
            case .english:
                return """
                You are a personal life analytics AI assistant.
                Respond entirely in English.
                Address the user as "you" in a friendly but professional tone.
                Use metric system for measurements (kg, km, hours).
                Date format: Month Day, Year (e.g., March 7, 2026).
                """
            }
        }
    }
    
    // MARK: - Properties
    
    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults(suiteName: "com.lifeanalytics.defaults")?
                .set(currentLanguage.rawValue, forKey: "app_language")
        }
    }
    
    // MARK: - Init
    
    init() {
        // 1. Önce kullanıcının manuel seçimini kontrol et
        if let saved = UserDefaults(suiteName: "com.lifeanalytics.defaults")?
            .string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        }
        // 2. Yoksa cihaz dilini kullan
        else if let deviceLang = Locale.current.language.languageCode?.identifier,
                deviceLang.starts(with: "tr") {
            self.currentLanguage = .turkish
        }
        // 3. Default: İngilizce
        else {
            self.currentLanguage = .english
        }
    }
    
    // MARK: - Localized String Helper
    
    func localized(_ key: String) -> String {
        // Bundle'dan dile göre string çek
        let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj")
        let bundle = path != nil ? (Bundle(path: path!) ?? .main) : .main
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
    
    // MARK: - AI System Prompt
    
    var aiSystemPrompt: String {
        return currentLanguage.systemPromptInstruction
    }
}
```

---

## ADIM 2 — Localizable.strings Dosyaları Oluştur

### Türkçe: `Resources/tr.lproj/Localizable.strings`

```strings
/* ===== TAB BAR ===== */
"tab.home" = "Ana Sayfa";
"tab.insights" = "Keşifler";
"tab.report" = "Rapor";
"tab.settings" = "Ayarlar";

/* ===== HOME SCREEN ===== */
"home.greeting.morning" = "Günaydın 👋";
"home.greeting.afternoon" = "İyi günler 👋";
"home.greeting.evening" = "İyi akşamlar 👋";
"home.title" = "Bugünün İçgörüsü";
"home.mood_cta" = "Bugün nasıl hissediyorsun?";
"home.mood_cta_sub" = "2 dokunuş ile kaydet →";
"home.ai_discoveries" = "AI Keşifleri";
"home.new_this_week" = "Bu hafta · %d yeni";

/* ===== STATS ===== */
"stats.sleep" = "Uyku";
"stats.mood" = "Ruh Hali";
"stats.meetings" = "Toplantı";
"stats.steps" = "Adım";
"stats.hours" = "saat";
"stats.today" = "bugün";
"stats.avg" = "ort.";
"stats.vs_last_week" = "vs geçen hafta";

/* ===== MOOD ENTRY ===== */
"mood.title" = "Ruh Hali Kaydı";
"mood.question" = "Bugün nasıl hissediyorsun?";
"mood.very_bad" = "Çok Kötü";
"mood.bad" = "Kötü";
"mood.neutral" = "Normal";
"mood.good" = "İyi";
"mood.very_good" = "Çok İyi";
"mood.activities_question" = "Bugün ne yaptın?";
"mood.add_note" = "Not ekle (opsiyonel)";
"mood.note_placeholder" = "Bugün hakkında kısa bir not...";
"mood.save" = "Kaydet";
"mood.saved" = "Kaydedildi!";
"mood.saved_detail" = "Ruh halin ve aktivitelerin bugünün analizine eklendi. AI yeni paternler arayacak.";
"mood.back_home" = "Ana Ekrana Dön";

/* ===== ACTIVITIES ===== */
"activity.exercise" = "Spor";
"activity.work" = "İş";
"activity.social" = "Sosyal";
"activity.reading" = "Okuma";
"activity.meditation" = "Meditasyon";
"activity.nature" = "Doğa";
"activity.family" = "Aile";
"activity.creative" = "Yaratıcı";
"activity.travel" = "Seyahat";
"activity.music" = "Müzik";

/* ===== INSIGHTS ===== */
"insights.title" = "Keşifler";
"insights.subtitle" = "AI'ın yaşamında keşfettikleri";
"insights.ai_level" = "AI Tanıma Seviyesi";
"insights.data_days" = "%d gün veri";
"insights.patterns_found" = "%d patern keşfedildi";
"insights.confidence.low" = "Düşük";
"insights.confidence.medium" = "Orta";
"insights.confidence.high" = "Yüksek";
"insights.type.correlation" = "PATERN KEŞFİ";
"insights.type.anomaly" = "ANOMALİ";
"insights.type.prediction" = "TAHMİN";
"insights.type.trend" = "TREND";
"insights.type.seasonal" = "DÖNEMSEL";
"insights.type.profile" = "PROFİL";
"insights.feedback.helpful" = "👍 Faydalı";
"insights.feedback.not_helpful" = "Faydasız";
"insights.today" = "Bugün";
"insights.yesterday" = "Dün";
"insights.this_week" = "Bu hafta";
"insights.days_ago" = "%d gün önce";

/* ===== WEEKLY REPORT ===== */
"report.title" = "Haftalık Yaşam Raporu";
"report.ai_report" = "AI RAPORU";
"report.weekly_suggestion" = "Haftalık Öneri";
"report.mood_heatmap" = "Ruh Hali Haritası";
"report.last_weeks" = "Son %d Hafta";
"report.avg_sleep" = "Ort. Uyku";
"report.avg_mood" = "Ort. Mood";
"report.total_meetings" = "Toplantılar";
"report.avg_steps" = "Ort. Adım";

/* ===== SETTINGS ===== */
"settings.title" = "Ayarlar";
"settings.language" = "Dil / Language";
"settings.notifications" = "Bildirim Tercihleri";
"settings.data_sources" = "Veri Kaynakları";
"settings.privacy" = "Gizlilik ve Güvenlik";
"settings.appearance" = "Görünüm";
"settings.export" = "Veriyi Dışa Aktar";
"settings.account" = "Hesap";
"settings.about" = "Hakkında";
"settings.version" = "Sürüm";

/* ===== ONBOARDING ===== */
"onboarding.welcome.title" = "Life Analytics AI";
"onboarding.welcome.subtitle" = "Yaşamını anlamlandır";
"onboarding.welcome.body" = "Uyku, ruh hali ve takvim verilerini analiz ederek yaşamındaki gizli paternleri keşfet.";
"onboarding.welcome.start" = "Başlayalım";
"onboarding.health.title" = "Sağlık Verileri";
"onboarding.health.body" = "Uyku ve aktivite verilerini analiz etmemize izin ver. Veriler cihazında şifreli kalır.";
"onboarding.health.allow" = "Erişim Ver";
"onboarding.health.skip" = "Şimdilik Atla";
"onboarding.calendar.title" = "Takvim Erişimi";
"onboarding.calendar.body" = "Toplantı yoğunluğunun uykuna ve ruh haline etkisini analiz edelim.";
"onboarding.calendar.allow" = "Erişim Ver";
"onboarding.calendar.skip" = "Şimdilik Atla";
"onboarding.mood.title" = "İlk Ruh Hali Kaydın";
"onboarding.mood.body" = "Her gün sadece 2 dokunuşla ruh halini kaydet. AI paternleri keşfetsin.";
"onboarding.done.title" = "Hazırsın! 🎉";
"onboarding.done.body" = "Veriler biriktikçe AI seni daha iyi tanıyacak. İlk içgörün yaklaşık 2 hafta içinde hazır olacak.";
"onboarding.done.start" = "Keşfetmeye Başla";

/* ===== NOTIFICATIONS ===== */
"notification.morning.title" = "Günaydın ☀️";
"notification.evening.title" = "Bugün Nasıl Geçti?";
"notification.evening.body" = "Ruh halini kaydet, bugünün özetini gör.";
"notification.weekly.title" = "Haftalık Raporun Hazır 📊";
"notification.weekly.body" = "AI bu hafta yeni bir patern keşfetti. İncele →";

/* ===== ERRORS ===== */
"error.healthkit_unavailable" = "Bu cihazda sağlık verileri kullanılamıyor.";
"error.healthkit_denied" = "Sağlık verilerine erişim izni gerekli.";
"error.calendar_denied" = "Takvim erişim izni gerekli.";
"error.insufficient_data" = "İçgörü için en az %d günlük veri gerekli. Mevcut: %d gün.";
"error.network" = "Bağlantı hatası. Lütfen internet bağlantını kontrol et.";
"error.llm" = "AI yanıt üretemedi. Lütfen tekrar dene.";
"error.rate_limit" = "Çok fazla istek. Lütfen biraz bekle.";
"error.unknown" = "Beklenmeyen bir hata oluştu.";
"error.retry" = "Tekrar Dene";
"error.ok" = "Tamam";

/* ===== GENERAL ===== */
"general.cancel" = "İptal";
"general.done" = "Tamam";
"general.delete" = "Sil";
"general.edit" = "Düzenle";
"general.share" = "Paylaş";
"general.loading" = "Yükleniyor...";
"general.no_data" = "Henüz veri yok";
"general.coming_soon" = "Yakında";

/* ===== DATA PERIOD ===== */
"period.today" = "Bugün";
"period.this_week" = "Bu Hafta";
"period.this_month" = "Bu Ay";
"period.last_30_days" = "Son 30 Gün";
"period.last_90_days" = "Son 90 Gün";
"period.all_time" = "Tüm Zamanlar";

/* ===== DAYS ===== */
"day.mon" = "Pzt";
"day.tue" = "Sal";
"day.wed" = "Çar";
"day.thu" = "Per";
"day.fri" = "Cum";
"day.sat" = "Cmt";
"day.sun" = "Paz";
```

### İngilizce: `Resources/en.lproj/Localizable.strings`

```strings
/* ===== TAB BAR ===== */
"tab.home" = "Home";
"tab.insights" = "Insights";
"tab.report" = "Report";
"tab.settings" = "Settings";

/* ===== HOME SCREEN ===== */
"home.greeting.morning" = "Good morning 👋";
"home.greeting.afternoon" = "Good afternoon 👋";
"home.greeting.evening" = "Good evening 👋";
"home.title" = "Today's Insight";
"home.mood_cta" = "How are you feeling today?";
"home.mood_cta_sub" = "Log with 2 taps →";
"home.ai_discoveries" = "AI Discoveries";
"home.new_this_week" = "This week · %d new";

/* ===== STATS ===== */
"stats.sleep" = "Sleep";
"stats.mood" = "Mood";
"stats.meetings" = "Meetings";
"stats.steps" = "Steps";
"stats.hours" = "hrs";
"stats.today" = "today";
"stats.avg" = "avg";
"stats.vs_last_week" = "vs last week";

/* ===== MOOD ENTRY ===== */
"mood.title" = "Mood Log";
"mood.question" = "How are you feeling today?";
"mood.very_bad" = "Very Bad";
"mood.bad" = "Bad";
"mood.neutral" = "Okay";
"mood.good" = "Good";
"mood.very_good" = "Great";
"mood.activities_question" = "What did you do today?";
"mood.add_note" = "Add a note (optional)";
"mood.note_placeholder" = "A quick note about your day...";
"mood.save" = "Save";
"mood.saved" = "Saved!";
"mood.saved_detail" = "Your mood and activities have been added to today's analysis. AI will look for new patterns.";
"mood.back_home" = "Back to Home";

/* ===== ACTIVITIES ===== */
"activity.exercise" = "Exercise";
"activity.work" = "Work";
"activity.social" = "Social";
"activity.reading" = "Reading";
"activity.meditation" = "Meditation";
"activity.nature" = "Nature";
"activity.family" = "Family";
"activity.creative" = "Creative";
"activity.travel" = "Travel";
"activity.music" = "Music";

/* ===== INSIGHTS ===== */
"insights.title" = "Discoveries";
"insights.subtitle" = "What AI discovered in your life";
"insights.ai_level" = "AI Recognition Level";
"insights.data_days" = "%d days of data";
"insights.patterns_found" = "%d patterns discovered";
"insights.confidence.low" = "Low";
"insights.confidence.medium" = "Medium";
"insights.confidence.high" = "High";
"insights.type.correlation" = "PATTERN";
"insights.type.anomaly" = "ANOMALY";
"insights.type.prediction" = "PREDICTION";
"insights.type.trend" = "TREND";
"insights.type.seasonal" = "SEASONAL";
"insights.type.profile" = "PROFILE";
"insights.feedback.helpful" = "👍 Helpful";
"insights.feedback.not_helpful" = "Not Helpful";
"insights.today" = "Today";
"insights.yesterday" = "Yesterday";
"insights.this_week" = "This week";
"insights.days_ago" = "%d days ago";

/* ===== WEEKLY REPORT ===== */
"report.title" = "Weekly Life Report";
"report.ai_report" = "AI REPORT";
"report.weekly_suggestion" = "Weekly Suggestion";
"report.mood_heatmap" = "Mood Heatmap";
"report.last_weeks" = "Last %d Weeks";
"report.avg_sleep" = "Avg Sleep";
"report.avg_mood" = "Avg Mood";
"report.total_meetings" = "Meetings";
"report.avg_steps" = "Avg Steps";

/* ===== SETTINGS ===== */
"settings.title" = "Settings";
"settings.language" = "Language / Dil";
"settings.notifications" = "Notification Preferences";
"settings.data_sources" = "Data Sources";
"settings.privacy" = "Privacy & Security";
"settings.appearance" = "Appearance";
"settings.export" = "Export Data";
"settings.account" = "Account";
"settings.about" = "About";
"settings.version" = "Version";

/* ===== ONBOARDING ===== */
"onboarding.welcome.title" = "Life Analytics AI";
"onboarding.welcome.subtitle" = "Understand your life";
"onboarding.welcome.body" = "Discover hidden patterns in your life by analyzing your sleep, mood, and calendar data.";
"onboarding.welcome.start" = "Let's Begin";
"onboarding.health.title" = "Health Data";
"onboarding.health.body" = "Allow us to analyze your sleep and activity data. All data stays encrypted on your device.";
"onboarding.health.allow" = "Grant Access";
"onboarding.health.skip" = "Skip for Now";
"onboarding.calendar.title" = "Calendar Access";
"onboarding.calendar.body" = "Let us analyze how your meeting load affects your sleep and mood.";
"onboarding.calendar.allow" = "Grant Access";
"onboarding.calendar.skip" = "Skip for Now";
"onboarding.mood.title" = "Your First Mood Log";
"onboarding.mood.body" = "Log your mood daily with just 2 taps. Let AI discover your patterns.";
"onboarding.done.title" = "You're Ready! 🎉";
"onboarding.done.body" = "As data accumulates, AI will understand you better. Your first insight will be ready in about 2 weeks.";
"onboarding.done.start" = "Start Exploring";

/* ===== NOTIFICATIONS ===== */
"notification.morning.title" = "Good Morning ☀️";
"notification.evening.title" = "How Was Your Day?";
"notification.evening.body" = "Log your mood and see today's summary.";
"notification.weekly.title" = "Your Weekly Report is Ready 📊";
"notification.weekly.body" = "AI discovered a new pattern this week. Check it out →";

/* ===== ERRORS ===== */
"error.healthkit_unavailable" = "Health data is not available on this device.";
"error.healthkit_denied" = "Health data access permission is required.";
"error.calendar_denied" = "Calendar access permission is required.";
"error.insufficient_data" = "At least %d days of data needed for insights. Current: %d days.";
"error.network" = "Connection error. Please check your internet.";
"error.llm" = "AI couldn't generate a response. Please try again.";
"error.rate_limit" = "Too many requests. Please wait a moment.";
"error.unknown" = "An unexpected error occurred.";
"error.retry" = "Retry";
"error.ok" = "OK";

/* ===== GENERAL ===== */
"general.cancel" = "Cancel";
"general.done" = "Done";
"general.delete" = "Delete";
"general.edit" = "Edit";
"general.share" = "Share";
"general.loading" = "Loading...";
"general.no_data" = "No data yet";
"general.coming_soon" = "Coming Soon";

/* ===== DATA PERIOD ===== */
"period.today" = "Today";
"period.this_week" = "This Week";
"period.this_month" = "This Month";
"period.last_30_days" = "Last 30 Days";
"period.last_90_days" = "Last 90 Days";
"period.all_time" = "All Time";

/* ===== DAYS ===== */
"day.mon" = "Mon";
"day.tue" = "Tue";
"day.wed" = "Wed";
"day.thu" = "Thu";
"day.fri" = "Fri";
"day.sat" = "Sat";
"day.sun" = "Sun";
```

---

## ADIM 3 — String Extension (Kolay Kullanım)

`Core/Extensions/String+Localization.swift` dosyası oluştur:

```swift
import Foundation

extension String {
    var localized: String {
        // Bu statik erişim için — LanguageManager inject edilemediğinde
        let lang = UserDefaults(suiteName: "com.lifeanalytics.defaults")?
            .string(forKey: "app_language") ?? "en"
        let path = Bundle.main.path(forResource: lang, ofType: "lproj")
        let bundle = path != nil ? (Bundle(path: path!) ?? .main) : .main
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
    
    func localized(with args: CVarArg...) -> String {
        String(format: self.localized, arguments: args)
    }
}
```

Bu sayede tüm projede şu şekilde kullanılır:

```swift
// Basit kullanım:
Text("tab.home".localized)
Text("mood.question".localized)

// Parametreli:
Text("error.insufficient_data".localized(with: 14, 5))
// Türkçe çıktı: "İçgörü için en az 14 günlük veri gerekli. Mevcut: 5 gün."
// İngilizce çıktı: "At least 14 days of data needed for insights. Current: 5 days."

Text("home.new_this_week".localized(with: 3))
// Türkçe: "Bu hafta · 3 yeni"
// İngilizce: "This week · 3 new"
```

---

## ADIM 4 — Dil Seçim Ekranı

`Presentation/Screens/Settings/LanguageSelectionView.swift` dosyası oluştur:

```swift
import SwiftUI

struct LanguageSelectionView: View {
    @Environment(LanguageManager.self) var languageManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(LanguageManager.AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            languageManager.currentLanguage = lang
                        }
                        // Kısa gecikme ile kapat — UI güncellemesi görünsün
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Text(lang.flag)
                                .font(.title2)
                            
                            Text(lang.displayName)
                                .font(.body)
                                .foregroundStyle(Color("TextPrimary"))
                            
                            Spacer()
                            
                            if languageManager.currentLanguage == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color("PrimaryBlue"))
                                    .font(.title3)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("settings.language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("general.done".localized) { dismiss() }
                }
            }
        }
    }
}
```

---

## ADIM 5 — Settings Ekranına Dil Seçeneği Ekle

Mevcut `SettingsView.swift` dosyasında dil seçim satırını ekle:

```swift
// Settings listesinin EN ÜSTÜNE ekle:
@State private var showLanguagePicker = false

// List içine ekle (ilk sırada):
Button {
    showLanguagePicker = true
} label: {
    HStack {
        Label {
            Text("settings.language".localized)
        } icon: {
            Image(systemName: "globe")
        }
        Spacer()
        Text(languageManager.currentLanguage.flag + " " + languageManager.currentLanguage.displayName)
            .foregroundStyle(.secondary)
            .font(.subheadline)
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }
}
.sheet(isPresented: $showLanguagePicker) {
    LanguageSelectionView()
}
```

---

## ADIM 6 — NetworkManager'da AI Dil Entegrasyonu

`NetworkManager.swift` dosyasında `sendLLMRequest` metodunu güncelle.
System prompt'a dil bilgisini EKLE — mevcut kodun yapısını bozmadan:

```swift
// sendLLMRequest metodu içinde, body oluşturulan yerde:

// Kullanıcının dil tercihini al
let userLang = UserDefaults(suiteName: "com.lifeanalytics.defaults")?
    .string(forKey: "app_language") ?? "en"
let langInstruction = LanguageManager.AppLanguage(rawValue: userLang)?.systemPromptInstruction 
    ?? LanguageManager.AppLanguage.english.systemPromptInstruction

// System prompt'a dil talimatını ekle
let fullSystemPrompt = langInstruction + "\n\n" + systemPrompt

let body: [String: Any] = [
    "prompt": prompt,
    "system_prompt": fullSystemPrompt,  // ← Dil talimatı + orijinal prompt
    "model": AppConstants.API.llmModel,
    "max_tokens": AppConstants.API.maxTokens
]
```

Bu sayede:
- Kullanıcı Türkçe seçtiyse → Claude Türkçe yanıt verir
- Kullanıcı İngilizce seçtiyse → Claude İngilizce yanıt verir
- Proxy kodunda HİÇBİR DEĞİŞİKLİK gerekmez

---

## ADIM 7 — App Entry Point'e LanguageManager Ekle

`LifeAnalyticsAIApp.swift` dosyasında:

```swift
@main
struct LifeAnalyticsAIApp: App {
    @State private var languageManager = LanguageManager()
    // ... diğer mevcut @State'ler
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(languageManager)
                // ... diğer mevcut modifier'lar
        }
    }
}
```

---

## ADIM 8 — Mevcut Tüm Hardcoded Stringleri Değiştir

Projede tüm hardcoded Türkçe veya İngilizce stringleri bul ve `.localized` ile değiştir.

### Arama ve değiştirme kuralları:

```swift
// ❌ ESKİ — Hardcoded string
Text("Bugünün İçgörüsü")
Text("Ayarlar")
Text("Kaydet")
Button("Erişim Ver") { ... }

// ✅ YENİ — Localized string
Text("home.title".localized)
Text("settings.title".localized)
Text("mood.save".localized)
Button("onboarding.health.allow".localized) { ... }
```

### Tüm dosyaları tara:
1. Presentation/Screens/ altındaki TÜM .swift dosyaları
2. Presentation/Components/ altındaki TÜM .swift dosyaları
3. Core/Utilities/AppError.swift — hata mesajları
4. Notification içerikleri

### AppError.swift güncellemesi:

```swift
var errorDescription: String? {
    switch self {
    case .healthKitNotAvailable: 
        return "error.healthkit_unavailable".localized
    case .healthKitAuthorizationDenied: 
        return "error.healthkit_denied".localized
    case .insufficientData(let req, let cur): 
        return "error.insufficient_data".localized(with: req, cur)
    case .networkError: 
        return "error.network".localized
    case .llmError(let msg): 
        return "error.llm".localized + " (\(msg))"
    // ... diğer case'ler
    }
}
```

---

## ADIM 9 — Bildirim İçeriklerini Lokalize Et

Bildirim gönderen kodda (NotificationService veya benzeri) içerikleri lokalize et:

```swift
let content = UNMutableNotificationContent()
content.title = "notification.morning.title".localized
content.body = morningInsightText // Bu zaten AI'dan dile uygun geliyor

// Haftalık rapor bildirimi:
content.title = "notification.weekly.title".localized
content.body = "notification.weekly.body".localized
```

---

## KRİTİK KURALLAR

1. **Hiçbir yerde hardcoded UI string bırakma** — tüm kullanıcıya görünen metin .localized olmalı
2. **AI yanıtları otomatik dile uygun gelir** — system prompt'taki dil talimatı sayesinde
3. **Proxy kodunda DEĞİŞİKLİK YAPMA** — dil bilgisi system prompt içinde gider
4. **LanguageManager @Observable** — SwiftUI otomatik view günceller, dil değişince tüm ekranlar anında güncellenir
5. **Cihaz dili otomatik algılanır** — ilk açılışta TR cihaz → Türkçe, diğer → İngilizce
6. **Kullanıcı her zaman Settings'ten değiştirebilir**
7. **Localizable.strings dosya yolları DOĞRU olmalı**: `Resources/tr.lproj/Localizable.strings` ve `Resources/en.lproj/Localizable.strings`
8. **Xcode'da dosyaları Target'a eklemeyi unutma** — Build Phases > Copy Bundle Resources

---

## DOĞRULAMA

Tüm değişiklikler yapıldıktan sonra:
1. Cmd+B — hatasız build
2. Simulator'de çalıştır — cihaz dili Türkçe ise UI Türkçe gelmeli
3. Settings > Dil > English seç — tüm UI anında İngilizce'ye dönmeli
4. AI insight iste — yanıt seçili dilde gelmeli
5. Tekrar Türkçe'ye dön — her şey Türkçe dönmeli
6. Uygulamayı kapat-aç — dil tercihi korunmuş olmalı
7. Projede "Bugün" veya "Today" gibi hardcoded string araması yap — SIFIR sonuç çıkmalı (hepsi .localized olmalı)