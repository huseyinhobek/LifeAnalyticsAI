// MARK: - Presentation.Charts.Components

import SwiftUI

struct ChartEmptyState: View {
    let title: String
    let message: String
    let daysRequired: Int
    let daysCollected: Int

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "2A2D38"), lineWidth: 4)
                    .frame(width: 48, height: 48)

                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(
                        Color(hex: "7B9BFF"),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
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

    private var progress: CGFloat {
        guard daysRequired > 0 else { return 0 }
        return CGFloat(daysCollected) / CGFloat(daysRequired)
    }
}
