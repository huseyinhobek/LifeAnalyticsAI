// MARK: - Widgets.QuickMood

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

struct QuickMoodEntry: TimelineEntry {
    let date: Date
}

struct QuickMoodProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickMoodEntry {
        QuickMoodEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickMoodEntry) -> Void) {
        completion(QuickMoodEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickMoodEntry>) -> Void) {
        let entry = QuickMoodEntry(date: Date())
        let next = Calendar.current.date(byAdding: .hour, value: 2, to: entry.date) ?? entry.date
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct QuickMoodWidgetView: View {
    private let moodOptions: [(emoji: String, value: Int)] = [
        ("😞", 1),
        ("😕", 2),
        ("😐", 3),
        ("🙂", 4),
        ("😄", 5)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hizli Mood Girisi")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(moodOptions, id: \.value) { option in
                    Link(destination: quickMoodURL(value: option.value)) {
                        Text(option.emoji)
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Secim uygulamada mood ekranini acar")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func quickMoodURL(value: Int) -> URL {
        URL(string: "lifeanalytics://mood-entry?preset=\(value)") ?? URL(string: "lifeanalytics://mood-entry")!
    }
}

struct QuickMoodWidget: Widget {
    let kind = "QuickMoodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickMoodProvider()) { _ in
            QuickMoodWidgetView()
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Quick Mood")
        .description("Ana ekrandan hizli mood secimi yapin.")
    }
}
#endif
