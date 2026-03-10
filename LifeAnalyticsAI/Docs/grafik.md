# LIFE ANALYTICS AI — ANALİTİK TASARIM SİSTEMİ (CHART DESIGN SYSTEM)
# Bu promptu OpenAI Codex / Claude Code / Cursor'a ver.

---

## CONTEXT

LifeAnalyticsAI iOS uygulaması. Swift 5.9+ / SwiftUI / iOS 17.0+ / Clean Architecture.
Uygulama uyku, ruh hali ve takvim verilerini analiz ederek AI içgörüler üretiyor.
Mevcut grafikler temel seviyede. Bu prompt ile profesyonel bir analitik tasarım sistemi kurulacak.

Framework: Swift Charts (iOS 16+ built-in). Harici chart kütüphanesi KULLANMA.

---

## BÖLÜM 1 — CHART STYLE GUIDE (Tasarım Grameri)

`Presentation/Charts/ChartStyleGuide.swift` dosyası oluştur:

```swift
import SwiftUI
import Charts

// ═══════════════════════════════════════════════
// CHART DESIGN SYSTEM — Life Analytics AI
// Tüm grafikler bu dosyadaki tokenleri kullanır.
// Hiçbir grafik kendi rengini/fontunu tanımlamaz.
// ═══════════════════════════════════════════════

enum ChartStyleGuide {

    // ── Semantic Renk Paleti ──
    // Her veri tipi sabit bir renge sahiptir. Uygulama genelinde tutarlı.
    
    enum SemanticColor {
        static let sleep = Color(hex: "7B9BFF")       // Mavi — uyku her yerde bu renk
        static let mood = Color(hex: "5EDBA5")         // Mint — ruh hali her yerde bu renk
        static let meetings = Color(hex: "FFB547")     // Amber — toplantı her yerde bu renk
        static let steps = Color(hex: "FF9B6A")        // Turuncu — adım
        static let heartRate = Color(hex: "FF7B7B")    // Kırmızı — kalp hızı
        static let screenTime = Color(hex: "B79CFF")   // Lavanta — ekran süresi (gelecek)
        
        // Trend yönü renkleri
        static let positive = Color(hex: "5EDBA5")     // Yeşil — iyileşme
        static let negative = Color(hex: "FF7B7B")     // Kırmızı — kötüleşme
        static let neutral = Color(hex: "8B95B0")      // Gri — değişim yok
        
        // Güven seviyesi renkleri
        static let confidenceHigh = Color(hex: "5EDBA5")
        static let confidenceMedium = Color(hex: "FFB547")
        static let confidenceLow = Color(hex: "FF7B7B")
        
        // Karşılaştırma (önceki dönem)
        static let currentPeriod = Color(hex: "7B9BFF")
        static let previousPeriod = Color(hex: "7B9BFF").opacity(0.3)
        
        // Eksik veri
        static let missingData = Color(hex: "2A2D38")
    }
    
    // ── Gradient Tanımları ──
    // Area chart dolguları için. Her metrik kendi gradient'ına sahip.
    
    enum Gradient {
        static func areaFill(for color: Color) -> LinearGradient {
            LinearGradient(
                colors: [color.opacity(0.25), color.opacity(0.02)],
                startPoint: .top, endPoint: .bottom
            )
        }
        
        static func barFill(for color: Color) -> LinearGradient {
            LinearGradient(
                colors: [color, color.opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
    
    // ── Tipografi ──
    
    enum Typography {
        static let chartTitle = Font.system(size: 15, weight: .bold)
        static let insightText = Font.system(size: 13, weight: .medium)
        static let axisLabel = Font.system(size: 10, weight: .medium)
        static let tooltipValue = Font.system(size: 14, weight: .bold, design: .rounded)
        static let tooltipLabel = Font.system(size: 10, weight: .medium)
        static let annotationText = Font.system(size: 10, weight: .semibold)
        static let confidenceLabel = Font.system(size: 9, weight: .semibold)
        static let emptyStateTitle = Font.system(size: 16, weight: .semibold)
        static let emptyStateBody = Font.system(size: 13)
    }
    
    // ── Grid ve Axis ──
    
    enum Grid {
        static let lineColor = Color.white.opacity(0.04)
        static let axisColor = Color.white.opacity(0.08)
        static let lineWidth: CGFloat = 0.5
    }
    
    // ── Boyutlar ──
    
    enum Sizing {
        static let chartHeight: CGFloat = 200
        static let miniChartHeight: CGFloat = 48
        static let sparklineHeight: CGFloat = 32
        static let barCornerRadius: CGFloat = 4
        static let lineWidth: CGFloat = 2.5
        static let pointSize: CGFloat = 6
        static let selectedPointSize: CGFloat = 10
        static let annotationLineWidth: CGFloat = 1
        static let chartPadding: CGFloat = 16
    }
    
    // ── Animasyon ──
    
    enum Animation {
        static let chartAppear: SwiftUI.Animation = .spring(response: 0.6, dampingFraction: 0.8)
        static let tooltipAppear: SwiftUI.Animation = .spring(response: 0.3)
        static let periodSwitch: SwiftUI.Animation = .easeInOut(duration: 0.3)
    }
    
    // ── Zaman Filtreleri ──
    
    enum TimePeriod: String, CaseIterable, Identifiable {
        case week7 = "7g"
        case month30 = "30g"
        case quarter90 = "90g"
        case year365 = "1y"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .week7: return "7 " + "period.days_short".localized
            case .month30: return "30 " + "period.days_short".localized
            case .quarter90: return "90 " + "period.days_short".localized
            case .year365: return "1 " + "period.year_short".localized
            }
        }
        
        var days: Int {
            switch self {
            case .week7: return 7
            case .month30: return 30
            case .quarter90: return 90
            case .year365: return 365
            }
        }
        
        // Downsampling: uzun serilerde veri noktası azaltma
        var downsampleInterval: Int {
            switch self {
            case .week7: return 1      // Her gün
            case .month30: return 1     // Her gün
            case .quarter90: return 3   // 3 günde bir ortalama
            case .year365: return 7     // Haftalık ortalama
            }
        }
    }
    
    // ── Güven Seviyesi ──
    
    enum ConfidenceLevel: String {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return SemanticColor.confidenceLow
            case .medium: return SemanticColor.confidenceMedium
            case .high: return SemanticColor.confidenceHigh
            }
        }
        
        var label: String {
            switch self {
            case .low: return "insights.confidence.low".localized
            case .medium: return "insights.confidence.medium".localized
            case .high: return "insights.confidence.high".localized
            }
        }
    }
}

// ── Color Hex Extension ──

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
```

---

## BÖLÜM 2 — CHART DATA MODELLER

`Presentation/Charts/Models/ChartDataModels.swift` oluştur:

```swift
import Foundation

// Her grafik bu modelleri kullanır. Raw veriyi doğrudan chart'a verme.

struct TimeSeriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let isEstimated: Bool  // Eksik veri interpolasyonu mu?
    
    // Bağlam bilgisi (tooltip için)
    var comparisonToAverage: Double?  // +/- yüzde
    var annotation: String?            // Kritik nokta açıklaması
}

struct ComparisonDataSet {
    let current: [TimeSeriesPoint]
    let previous: [TimeSeriesPoint]
    let changePercentage: Double
}

struct CorrelationPoint: Identifiable {
    let id = UUID()
    let xValue: Double
    let yValue: Double
    let date: Date
    let xLabel: String
    let yLabel: String
}

struct CorrelationResult {
    let points: [CorrelationPoint]
    let rValue: Double          // Korelasyon katsayısı (-1 to 1)
    let pValue: Double          // İstatistiksel anlamlılık
    let sampleSize: Int
    let regressionSlope: Double
    let regressionIntercept: Double
    let confidence: ChartStyleGuide.ConfidenceLevel
    
    // Regression line noktaları
    var regressionLine: [(x: Double, y: Double)] {
        guard let minX = points.map(\.xValue).min(),
              let maxX = points.map(\.xValue).max() else { return [] }
        return [
            (x: minX, y: regressionSlope * minX + regressionIntercept),
            (x: maxX, y: regressionSlope * maxX + regressionIntercept)
        ]
    }
}

struct GaugeData {
    let value: Double       // 0-100
    let label: String
    let segments: [(range: ClosedRange<Double>, color: Color, label: String)]
}

// Downsampling utility
extension Array where Element == TimeSeriesPoint {
    func downsampled(interval: Int) -> [TimeSeriesPoint] {
        guard interval > 1 else { return self }
        var result: [TimeSeriesPoint] = []
        for i in stride(from: 0, to: count, by: interval) {
            let chunk = Array(self[i..<min(i + interval, count)])
            let avgValue = chunk.map(\.value).reduce(0, +) / Double(chunk.count)
            let hasEstimated = chunk.contains { $0.isEstimated }
            result.append(TimeSeriesPoint(
                date: chunk[chunk.count / 2].date,
                value: avgValue,
                isEstimated: hasEstimated
            ))
        }
        return result
    }
}
```

---

## BÖLÜM 3 — TEMEL CHART BİLEŞENLERİ

### 3A) Trend Line Chart (Uyku süresi, mood trendi)

`Presentation/Charts/Components/TrendLineChart.swift` oluştur:

```swift
import SwiftUI
import Charts

struct TrendLineChart: View {
    let title: String
    let insight: String?                   // "So what?" cümlesi
    let data: [TimeSeriesPoint]
    let color: Color
    let unit: String                       // "saat", "/5", "adet"
    let comparison: ComparisonDataSet?     // Önceki dönem (opsiyonel)
    let annotations: [TimeSeriesPoint]     // Kritik noktalar
    let period: ChartStyleGuide.TimePeriod
    
    @State private var selectedPoint: TimeSeriesPoint?
    @State private var showComparison = false
    
    init(
        title: String,
        insight: String? = nil,
        data: [TimeSeriesPoint],
        color: Color,
        unit: String,
        comparison: ComparisonDataSet? = nil,
        annotations: [TimeSeriesPoint] = [],
        period: ChartStyleGuide.TimePeriod = .week7
    ) {
        self.title = title
        self.insight = insight
        self.data = data
        self.color = color
        self.unit = unit
        self.comparison = comparison
        self.annotations = annotations
        self.period = period
    }
    
    private var processedData: [TimeSeriesPoint] {
        data.downsampled(interval: period.downsampleInterval)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Başlık + değer
            chartHeader
            
            // Insight cümlesi
            if let insight {
                Text(insight)
                    .font(ChartStyleGuide.Typography.insightText)
                    .foregroundStyle(Color(hex: "A0A8BE"))
                    .lineLimit(2)
            }
            
            // Tooltip (seçili nokta)
            if let selected = selectedPoint {
                tooltipView(for: selected)
            }
            
            // Chart
            Chart {
                // Önceki dönem (karşılaştırma modu)
                if showComparison, let prev = comparison?.previous {
                    ForEach(prev) { point in
                        LineMark(
                            x: .value("Tarih", point.date),
                            y: .value("Değer", point.value)
                        )
                        .foregroundStyle(ChartStyleGuide.SemanticColor.previousPeriod)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }
                }
                
                // Ana veri — Area fill
                ForEach(processedData) { point in
                    AreaMark(
                        x: .value("Tarih", point.date),
                        y: .value("Değer", point.value)
                    )
                    .foregroundStyle(ChartStyleGuide.Gradient.areaFill(for: color))
                    .interpolationMethod(.catmullRom)
                }
                
                // Ana veri — Line
                ForEach(processedData) { point in
                    LineMark(
                        x: .value("Tarih", point.date),
                        y: .value("Değer", point.value)
                    )
                    .foregroundStyle(point.isEstimated ? color.opacity(0.4) : color)
                    .lineStyle(StrokeStyle(
                        lineWidth: ChartStyleGuide.Sizing.lineWidth,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: point.isEstimated ? [4, 3] : []
                    ))
                    .interpolationMethod(.catmullRom)
                }
                
                // Seçili nokta
                if let selected = selectedPoint {
                    PointMark(
                        x: .value("Tarih", selected.date),
                        y: .value("Değer", selected.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(ChartStyleGuide.Sizing.selectedPointSize * ChartStyleGuide.Sizing.selectedPointSize)
                    
                    RuleMark(x: .value("Tarih", selected.date))
                        .foregroundStyle(color.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                
                // Annotation noktaları
                ForEach(annotations) { ann in
                    PointMark(
                        x: .value("Tarih", ann.date),
                        y: .value("Değer", ann.value)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(30)
                    .annotation(position: .top, spacing: 4) {
                        if let text = ann.annotation {
                            Text(text)
                                .font(ChartStyleGuide.Typography.annotationText)
                                .foregroundStyle(ChartStyleGuide.SemanticColor.negative)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(hex: "1E2540"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .frame(height: ChartStyleGuide.Sizing.chartHeight)
            .chartXAxis {
                AxisMarks(values: .stride(by: period == .week7 ? .day : .weekOfYear, count: 1)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: ChartStyleGuide.Grid.lineWidth))
                        .foregroundStyle(ChartStyleGuide.Grid.lineColor)
                    AxisValueLabel()
                        .font(ChartStyleGuide.Typography.axisLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: ChartStyleGuide.Grid.lineWidth))
                        .foregroundStyle(ChartStyleGuide.Grid.lineColor)
                    AxisValueLabel()
                        .font(ChartStyleGuide.Typography.axisLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let x = drag.location.x - geo[proxy.plotAreaFrame].origin.x
                                    guard let date: Date = proxy.value(atX: x) else { return }
                                    if let closest = processedData.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    }) {
                                        withAnimation(ChartStyleGuide.Animation.tooltipAppear) {
                                            selectedPoint = closest
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation { selectedPoint = nil }
                                }
                        )
                }
            }
            .animation(ChartStyleGuide.Animation.chartAppear, value: processedData.count)
            
            // Karşılaştırma toggle
            if comparison != nil {
                compareToggle
            }
        }
        .padding(ChartStyleGuide.Sizing.chartPadding)
        .background(Color(hex: "12141A"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
    
    // ── Sub-views ──
    
    private var chartHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ChartStyleGuide.Typography.chartTitle)
                    .foregroundStyle(Color(hex: "F2F4F8"))
                
                if let last = processedData.last {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", last.value))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(color)
                        Text(unit)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "8B95B0"))
                    }
                }
            }
            
            Spacer()
            
            // Trend badge
            if processedData.count >= 2 {
                let first = processedData.first!.value
                let last = processedData.last!.value
                let change = first > 0 ? ((last - first) / first) * 100 : 0
                
                HStack(spacing: 3) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(String(format: "%.0f%%", abs(change)))
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(change >= 0 ? ChartStyleGuide.SemanticColor.positive : ChartStyleGuide.SemanticColor.negative)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((change >= 0 ? ChartStyleGuide.SemanticColor.positive : ChartStyleGuide.SemanticColor.negative).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private func tooltipView(for point: TimeSeriesPoint) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(point.date, style: .date)
                    .font(ChartStyleGuide.Typography.tooltipLabel)
                    .foregroundStyle(Color(hex: "8B95B0"))
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(format: "%.1f", point.value))
                        .font(ChartStyleGuide.Typography.tooltipValue)
                        .foregroundStyle(color)
                    Text(unit)
                        .font(ChartStyleGuide.Typography.tooltipLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }
            
            if let comp = point.comparisonToAverage {
                Divider().frame(height: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("chart.vs_average".localized)
                        .font(ChartStyleGuide.Typography.tooltipLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                    Text(String(format: "%+.0f%%", comp))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(comp >= 0 ? ChartStyleGuide.SemanticColor.positive : ChartStyleGuide.SemanticColor.negative)
                }
            }
        }
        .padding(10)
        .background(Color(hex: "1E2540"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private var compareToggle: some View {
        Button {
            withAnimation(ChartStyleGuide.Animation.periodSwitch) {
                showComparison.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .stroke(showComparison ? color : Color(hex: "5C6380"), lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                    .overlay {
                        if showComparison {
                            Circle().fill(color).frame(width: 8, height: 8)
                        }
                    }
                Text("chart.compare_previous".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "8B95B0"))
            }
        }
    }
}
```

### 3B) Bar Comparison Chart (Hafta içi vs hafta sonu, gün bazlı karşılaştırma)

`Presentation/Charts/Components/ComparisonBarChart.swift` oluştur:

```swift
import SwiftUI
import Charts

struct ComparisonBarChart: View {
    let title: String
    let insight: String?
    let data: [BarDataPoint]
    let color: Color
    let unit: String
    
    @State private var selectedBar: BarDataPoint?
    
    struct BarDataPoint: Identifiable {
        let id = UUID()
        let label: String           // "Pzt", "Sal" vs.
        let value: Double
        let isHighlighted: Bool     // Ortalamadan sapma
        let comparisonValue: Double? // Önceki dönem
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text(title)
                .font(ChartStyleGuide.Typography.chartTitle)
                .foregroundStyle(Color(hex: "F2F4F8"))
            
            if let insight {
                Text(insight)
                    .font(ChartStyleGuide.Typography.insightText)
                    .foregroundStyle(Color(hex: "A0A8BE"))
            }
            
            // Chart
            Chart(data) { point in
                BarMark(
                    x: .value("Gün", point.label),
                    y: .value("Değer", point.value)
                )
                .foregroundStyle(
                    point.isHighlighted
                    ? ChartStyleGuide.Gradient.barFill(for: color)
                    : ChartStyleGuide.Gradient.barFill(for: color.opacity(0.4))
                )
                .cornerRadius(ChartStyleGuide.Sizing.barCornerRadius)
                
                // Önceki dönem overlay
                if let comp = point.comparisonValue {
                    BarMark(
                        x: .value("Gün", point.label),
                        y: .value("Önceki", comp)
                    )
                    .foregroundStyle(Color.clear)
                    .overlay {
                        // Önceki dönem çizgi işareti
                        Rectangle()
                            .fill(ChartStyleGuide.SemanticColor.previousPeriod)
                            .frame(height: 2)
                    }
                }
            }
            .frame(height: ChartStyleGuide.Sizing.chartHeight)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(ChartStyleGuide.Typography.axisLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: ChartStyleGuide.Grid.lineWidth))
                        .foregroundStyle(ChartStyleGuide.Grid.lineColor)
                    AxisValueLabel()
                        .font(ChartStyleGuide.Typography.axisLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }
        }
        .padding(ChartStyleGuide.Sizing.chartPadding)
        .background(Color(hex: "12141A"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.04), lineWidth: 1))
    }
}
```

### 3C) Correlation Scatter Chart (Uyku vs Mood, Toplantı vs Uyku)

`Presentation/Charts/Components/CorrelationScatterChart.swift` oluştur:

```swift
import SwiftUI
import Charts

struct CorrelationScatterChart: View {
    let title: String
    let insight: String?
    let result: CorrelationResult
    let xLabel: String
    let yLabel: String
    let xColor: Color
    let yColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text(title)
                .font(ChartStyleGuide.Typography.chartTitle)
                .foregroundStyle(Color(hex: "F2F4F8"))
            
            if let insight {
                Text(insight)
                    .font(ChartStyleGuide.Typography.insightText)
                    .foregroundStyle(Color(hex: "A0A8BE"))
            }
            
            // Güven bandı
            confidenceBadge
            
            // Chart
            Chart {
                // Scatter noktaları
                ForEach(result.points) { point in
                    PointMark(
                        x: .value(xLabel, point.xValue),
                        y: .value(yLabel, point.yValue)
                    )
                    .foregroundStyle(xColor.opacity(0.7))
                    .symbolSize(40)
                }
                
                // Regression çizgisi
                if result.regressionLine.count == 2 {
                    let line = result.regressionLine
                    LineMark(
                        x: .value(xLabel, line[0].x),
                        y: .value(yLabel, line[0].y)
                    )
                    .foregroundStyle(ChartStyleGuide.SemanticColor.negative.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    
                    LineMark(
                        x: .value(xLabel, line[1].x),
                        y: .value(yLabel, line[1].y)
                    )
                    .foregroundStyle(ChartStyleGuide.SemanticColor.negative.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }
            .frame(height: ChartStyleGuide.Sizing.chartHeight)
            .chartXAxisLabel(position: .bottom, alignment: .center) {
                Text(xLabel)
                    .font(ChartStyleGuide.Typography.axisLabel)
                    .foregroundStyle(Color(hex: "5C6380"))
            }
            .chartYAxisLabel(position: .leading, alignment: .center) {
                Text(yLabel)
                    .font(ChartStyleGuide.Typography.axisLabel)
                    .foregroundStyle(Color(hex: "5C6380"))
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: ChartStyleGuide.Grid.lineWidth))
                        .foregroundStyle(ChartStyleGuide.Grid.lineColor)
                    AxisValueLabel()
                        .font(ChartStyleGuide.Typography.axisLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: ChartStyleGuide.Grid.lineWidth))
                        .foregroundStyle(ChartStyleGuide.Grid.lineColor)
                    AxisValueLabel()
                        .font(ChartStyleGuide.Typography.axisLabel)
                        .foregroundStyle(Color(hex: "5C6380"))
                }
            }
            
            // R değeri ve sample size
            statisticsFooter
        }
        .padding(ChartStyleGuide.Sizing.chartPadding)
        .background(Color(hex: "12141A"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.04), lineWidth: 1))
    }
    
    private var confidenceBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(result.confidence.color)
                .frame(width: 6, height: 6)
            Text("chart.confidence".localized + ": " + result.confidence.label)
                .font(ChartStyleGuide.Typography.confidenceLabel)
                .foregroundStyle(result.confidence.color)
            
            Text("·")
                .foregroundStyle(Color(hex: "5C6380"))
            
            Text("n=\(result.sampleSize)")
                .font(ChartStyleGuide.Typography.confidenceLabel)
                .foregroundStyle(Color(hex: "5C6380"))
        }
    }
    
    private var statisticsFooter: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 1) {
                Text("r")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(hex: "5C6380"))
                Text(String(format: "%.2f", result.rValue))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "A0A8BE"))
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("p")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(hex: "5C6380"))
                Text(result.pValue < 0.001 ? "<0.001" : String(format: "%.3f", result.pValue))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(result.pValue < 0.05 ? ChartStyleGuide.SemanticColor.positive : Color(hex: "A0A8BE"))
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("chart.sample_size".localized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "5C6380"))
                Text("\(result.sampleSize) " + "chart.days".localized)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "A0A8BE"))
            }
        }
        .padding(.top, 4)
    }
}
```

---

## BÖLÜM 4 — ORTAK BİLEŞENLER

### 4A) Zaman Filtresi

`Presentation/Charts/Components/TimePeriodPicker.swift`:

```swift
import SwiftUI

struct TimePeriodPicker: View {
    @Binding var selected: ChartStyleGuide.TimePeriod
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(ChartStyleGuide.TimePeriod.allCases) { period in
                Button {
                    withAnimation(ChartStyleGuide.Animation.periodSwitch) {
                        selected = period
                    }
                } label: {
                    Text(period.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selected == period ? .white : Color(hex: "5C6380"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selected == period
                            ? Color(hex: "7B9BFF")
                            : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(3)
        .background(Color(hex: "1A1D27"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
```

### 4B) Empty State

`Presentation/Charts/Components/ChartEmptyState.swift`:

```swift
import SwiftUI

struct ChartEmptyState: View {
    let title: String
    let message: String
    let daysRequired: Int
    let daysCollected: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(hex: "2A2D38"), lineWidth: 4)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: CGFloat(daysCollected) / CGFloat(daysRequired))
                    .stroke(Color(hex: "7B9BFF"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                Text("\(daysCollected)/\(daysRequired)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "8B95B0"))
            }
            
            Text(title)
                .font(ChartStyleGuide.Typography.emptyStateTitle)
                .foregroundStyle(Color(hex: "F2F4F8"))
            
            Text(message)
                .font(ChartStyleGuide.Typography.emptyStateBody)
                .foregroundStyle(Color(hex: "5C6380"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(height: ChartStyleGuide.Sizing.chartHeight)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "12141A"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.04), lineWidth: 1))
    }
}
```

### 4C) Sparkline (Stat kartları içi mini grafik)

`Presentation/Charts/Components/SparklineView.swift`:

```swift
import SwiftUI
import Charts

struct SparklineView: View {
    let data: [Double]
    let color: Color
    let height: CGFloat
    
    init(data: [Double], color: Color, height: CGFloat = ChartStyleGuide.Sizing.sparklineHeight) {
        self.data = data
        self.color = color
        self.height = height
    }
    
    var body: some View {
        Chart(Array(data.enumerated()), id: \.offset) { index, value in
            AreaMark(
                x: .value("i", index),
                y: .value("v", value)
            )
            .foregroundStyle(ChartStyleGuide.Gradient.areaFill(for: color))
            .interpolationMethod(.catmullRom)
            
            LineMark(
                x: .value("i", index),
                y: .value("v", value)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
    }
}
```

---

## BÖLÜM 5 — ACCESSIBILITY

Tüm chart bileşenlerine şu accessibility modifier'ları ekle:

```swift
// Her chart'ın body'sine ekle:
.accessibilityElement(children: .ignore)
.accessibilityLabel(title)
.accessibilityValue(accessibilitySummary)

// Computed property olarak:
private var accessibilitySummary: String {
    guard let last = processedData.last else { return "chart.no_data".localized }
    return String(format: "chart.accessibility_summary".localized, 
                  String(format: "%.1f", last.value), unit)
}
```

Renk körlüğü için: Tüm renklerde kontrast oranı minimum 4.5:1. Trend yönü sadece renge değil, ok yönüne de bağlı (arrow.up.right / arrow.down.right).

---

## BÖLÜM 6 — MEVCUT EKRANLARA ENTEGRASYON

### HomeView'da:
- Stat kartlarındaki mini grafikleri SparklineView ile değiştir
- Her stat kartında semantic renk kullan (uyku: sleep rengi, mood: mood rengi)

### DashboardView / InsightsView'da:
- Uyku trendi: TrendLineChart(title:, color: ChartStyleGuide.SemanticColor.sleep, ...)
- Mood trendi: TrendLineChart(title:, color: ChartStyleGuide.SemanticColor.mood, ...)
- Gün bazlı karşılaştırma: ComparisonBarChart
- TimePeriodPicker ile 7g/30g/90g/1y filtre

### WeeklyReportView'da:
- Haftalık trend çizgisi
- Mood heatmap (mevcut haliyle kalabilir)
- Bu hafta vs geçen hafta ComparisonBarChart

### Korelasyon ekranında (premium):
- Uyku vs Mood: CorrelationScatterChart
- Toplantı vs Uyku: CorrelationScatterChart
- Her chart'ta güven seviyesi ve p-value görünür

### Yetersiz veri durumunda:
- ChartEmptyState göster (kaç gün veri var, kaç gün gerekli)

---

## BÖLÜM 7 — LOCALIZABLE STRINGS EKLEMELERİ

tr.lproj:
```
"chart.vs_average" = "Ortalamaya göre";
"chart.confidence" = "Güven";
"chart.sample_size" = "Örneklem";
"chart.days" = "gün";
"chart.compare_previous" = "Önceki dönemi karşılaştır";
"chart.no_data" = "Henüz yeterli veri yok";
"chart.accessibility_summary" = "Son değer: %@ %@";
"period.days_short" = "gün";
"period.year_short" = "yıl";
"chart.collecting" = "Veri toplanıyor";
"chart.collecting_detail" = "Bu grafik için en az %d günlük veri gerekli. Şu ana kadar %d gün toplandı.";
```

en.lproj karşılıklarını da ekle.

---

## KRİTİK KURALLAR

1. Tüm grafikler ChartStyleGuide'dan token alır — kendi rengini/fontunu tanımlamaz.
2. Her grafik başında "So what?" insight cümlesi olmalı (opsiyonel ama önerilen).
3. Swift Charts (built-in) kullan — harici kütüphane KULLANMA.
4. Tooltip'lerde sadece değer değil, ortalamaya göre +/-% göster.
5. Eksik veri noktalarını kesik çizgi (dash) ile göster.
6. 90+ günlük serilerde downsampling uygula.
7. Korelasyon chart'larında p-value ve sample size MUTLAKA göster.
8. Dark mode primary — tüm renkler koyu arka plan üzerinde okunabilir olmalı.
9. VoiceOver: Her chart'ın accessibility summary'si olmalı.
10. Emoji ve ikon KULLANMA — tipografi, renk ve geometri ile vurgu yap.

---

## DOĞRULAMA

1. Cmd+B — hatasız build
2. ChartStyleGuide.SemanticColor.sleep kullan — her yerde aynı mavi
3. TrendLineChart preview — data ile render etmeli
4. Boş data ile ChartEmptyState göstermeli
5. TimePeriodPicker 7g→30g geçişinde animasyon olmalı
6. CorrelationScatterChart'ta r ve p değerleri görünmeli
7. Dark mode'da tüm text'ler okunabilir olmalı
8. VoiceOver ile chart'lar okunabilir olmalı