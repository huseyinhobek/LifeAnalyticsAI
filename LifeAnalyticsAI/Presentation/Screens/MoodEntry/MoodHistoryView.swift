// MARK: - Presentation.Screens.MoodEntry

import SwiftUI
import Charts

struct MoodHistoryView: View {
    @StateObject private var viewModel: MoodHistoryViewModel

    init(viewModel: MoodHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var lastYearDays: [Date] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        return (0..<365).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Mood Gecmisi")
                    .font(Theme.titleFont)
                    .foregroundStyle(Color("TextPrimary"))

                Text("Son 365 gun")
                    .font(Theme.captionFont)
                    .foregroundStyle(Color("TextSecondary"))

                if !viewModel.entries.isEmpty {
                    moodTrendChart
                    moodDistributionChart
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 14), spacing: 4) {
                    ForEach(lastYearDays, id: \.self) { day in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color(for: day))
                            .frame(height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color("TextSecondary").opacity(0.08), lineWidth: 0.5)
                            )
                    }
                }

                Text("Kayit Listesi")
                    .font(Theme.headlineFont)
                    .foregroundStyle(Color("TextPrimary"))

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if viewModel.entries.isEmpty {
                    Text("Henuz mood kaydi bulunmuyor.")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Color("TextSecondary"))
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.entries.prefix(30)) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Text(entry.moodLevel.emoji)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color("TextPrimary"))

                                    Text(entry.activities.map { $0.displayName }.joined(separator: ", "))
                                        .font(Theme.captionFont)
                                        .foregroundStyle(Color("TextSecondary"))

                                    if let note = entry.note, !note.isEmpty {
                                        Text(note)
                                            .font(Theme.captionFont)
                                            .foregroundStyle(Color("TextPrimary"))
                                    }
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(Color("BackgroundLight"))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        }
                    }
                }
            }
            .padding(Theme.paddingLarge)
        }
        .background(Color("BackgroundLight").opacity(0.4))
        .navigationTitle("Mood Gecmisi")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadLastYear()
        }
    }

    private var moodTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood Trend")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Chart(viewModel.trendPoints) { point in
                LineMark(
                    x: .value("Tarih", point.date),
                    y: .value("Mood", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color("PrimaryBlue"))

                AreaMark(
                    x: .value("Tarih", point.date),
                    y: .value("Mood", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("PrimaryBlue").opacity(0.24), Color("PrimaryBlue").opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYScale(domain: 1...5)
            .frame(height: 180)
            .padding(12)
            .background(Color("BackgroundLight"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private var moodDistributionChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood Dagilimi")
                .font(Theme.headlineFont)
                .foregroundStyle(Color("TextPrimary"))

            Chart(viewModel.distributionPoints) { point in
                BarMark(
                    x: .value("Mood", point.label),
                    y: .value("Adet", point.count)
                )
                .foregroundStyle(Theme.moodColor(point.value))
                .cornerRadius(6)
            }
            .frame(height: 180)
            .padding(12)
            .background(Color("BackgroundLight"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private func color(for day: Date) -> Color {
        guard let entry = viewModel.moodEntry(for: day) else {
            return Color("BackgroundLight")
        }
        return Theme.moodColor(entry.value).opacity(0.9)
    }
}
