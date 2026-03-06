# LifeAnalyticsAI

LifeAnalyticsAI, kullanicinin ruh hali, saglik ve takvim verilerini analiz ederek anlamli icgoruler uretmeyi hedefleyen iOS uygulamasidir.

## Mimari Ozeti

Proje **Clean Architecture** prensipleri ile katmanli olarak kurgulanmistir:

- `App/`: Uygulama giris noktasi, app delegate ve dependency container
- `Core/`: Ortak sabitler, protokoller, extension ve utility yapilari
- `Domain/`: Model, use case ve repository protocol tanimlari
- `Data/`: Veri kaynaklari, repository implementasyonlari ve persistence
- `Presentation/`: Ekranlar, view model'ler, navigation ve UI component'leri
- `Resources/`: Asset, localization ve font kaynaklari

## Kurulum

1. Xcode 16+ kurulu oldugundan emin olun.
2. Projeyi klonlayin.
3. Proje kok dizininde paket bagimliliklarini cozumleyin:

```bash
xcodebuild -resolvePackageDependencies -project "LifeAnalyticsAI.xcodeproj"
```

4. Xcode ile `LifeAnalyticsAI.xcodeproj` dosyasini acin.
5. `LifeAnalyticsAI` scheme secip calistirin.

## Branch Stratejisi

- `main`: production-ready
- `develop`: aktif gelistirme
- `feature/LAI-XXX`: her ticket icin feature branch
- `release/vX.Y.Z`: yayin hazirligi
