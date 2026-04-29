import SwiftUI

/// Compact row summarizing a single metric's current value and recent trend.
/// Designed to stack in a list on the dashboard.
struct MetricTrendRow: View {
    let summary: ProgressTracker.Summary

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            iconBadge

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.metric.rawValue)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text("Best \(String(format: "%.1f", summary.best)) · \(summary.sampleCount) scans")
                    .font(DesignSystem.Typography.caption(12))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            trendBadge
        }
        .padding(DesignSystem.Spacing.md)
        .glassCard(cornerRadius: DesignSystem.CornerRadius.medium)
    }

    private var iconBadge: some View {
        Image(systemName: summary.metric.systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(DesignSystem.Colors.accentCyan)
            .frame(width: 36, height: 36)
            .background(
                Circle().fill(DesignSystem.Colors.surfaceTertiary)
            )
    }

    private var trendBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: summary.direction.systemImage)
            Text(changeText)
        }
        .font(DesignSystem.Typography.mono(13))
        .foregroundColor(trendColor)
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(trendColor.opacity(0.12))
        )
    }

    private var changeText: String {
        let sign = summary.netChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", summary.netChange))"
    }

    private var trendColor: Color {
        switch summary.direction {
        case .up: return DesignSystem.Colors.success
        case .down: return DesignSystem.Colors.error
        case .flat: return DesignSystem.Colors.textSecondary
        }
    }
}
