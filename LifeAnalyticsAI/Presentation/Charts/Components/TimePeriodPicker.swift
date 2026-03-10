// MARK: - Presentation.Charts.Components

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
                        .background(selected == period ? Color(hex: "7B9BFF") : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(3)
        .background(Color(hex: "1A1D27"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
