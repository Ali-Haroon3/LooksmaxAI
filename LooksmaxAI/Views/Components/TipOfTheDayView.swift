import SwiftUI

/// Dashboard card surfacing the day's insight from `InsightsLibrary`.
struct TipOfTheDayView: View {
    var date: Date = Date()

    private var insight: InsightsLibrary.Insight {
        InsightsLibrary.insight(for: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(DesignSystem.Colors.warning)
                Text("TIP OF THE DAY")
                    .font(DesignSystem.Typography.caption(11))
                    .tracking(1.5)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                Spacer()
                Label(insight.category.rawValue, systemImage: insight.category.icon)
                    .font(DesignSystem.Typography.caption(11))
                    .foregroundColor(DesignSystem.Colors.accentCyan)
            }

            Text(insight.headline)
                .font(DesignSystem.Typography.title(17))
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text(insight.body)
                .font(DesignSystem.Typography.caption(13))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .glassCard()
    }
}
