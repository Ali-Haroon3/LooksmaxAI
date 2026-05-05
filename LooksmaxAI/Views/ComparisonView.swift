import SwiftUI
import SwiftData

/// Before/after comparison of the user's first and most recent scans, with a
/// per-metric breakdown of what moved.
struct ComparisonView: View {
    @Query(sort: \ScanHistory.scannedAt) private var scans: [ScanHistory]

    private var result: ScanComparison.Result? {
        ScanComparison.compareFirstAndLast(scans)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    if let result {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            overallCard(result)
                            metricsCard(result)
                            highlightCard(result)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.bottom, DesignSystem.Spacing.xxl)
                    } else {
                        emptyState
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Cards

    private func overallCard(_ result: ScanComparison.Result) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.xl) {
                scorePillar(title: "Before", value: result.overallBefore)
                Image(systemName: "arrow.right")
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                scorePillar(title: "After", value: result.overallAfter)
            }

            Text(deltaLabel(result.overallDelta) + " over \(result.daysBetween) days")
                .font(DesignSystem.Typography.caption())
                .foregroundColor(result.overallDelta >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func scorePillar(title: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(DesignSystem.Typography.caption(12))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text(String(format: "%.1f", value))
                .font(DesignSystem.Typography.display(36))
                .foregroundColor(value.scoreColor)
        }
    }

    private func metricsCard(_ result: ScanComparison.Result) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(result.deltas) { delta in
                HStack {
                    Text(delta.label)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Text(String(format: "%.1f → %.1f", delta.before, delta.after))
                        .font(DesignSystem.Typography.mono(13))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Image(systemName: delta.direction.systemImage)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color(for: delta.direction))
                        .frame(width: 20)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .glassCard()
    }

    @ViewBuilder
    private func highlightCard(_ result: ScanComparison.Result) -> some View {
        if let gain = result.biggestGain {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(DesignSystem.Colors.warning)
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Biggest gain")
                        .font(DesignSystem.Typography.caption(12))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("\(gain.label) \(deltaLabel(gain.delta))")
                        .font(DesignSystem.Typography.title(15))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .glassCard(cornerRadius: DesignSystem.CornerRadius.medium)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            Text("Not enough scans yet")
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text("Complete at least two scans to compare your progress.")
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, DesignSystem.Spacing.xxxl)
        .padding(.horizontal, DesignSystem.Spacing.xl)
    }

    // MARK: - Helpers

    private func deltaLabel(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))"
    }

    private func color(for direction: TrendDirection) -> Color {
        switch direction {
        case .up: return DesignSystem.Colors.success
        case .down: return DesignSystem.Colors.error
        case .flat: return DesignSystem.Colors.textTertiary
        }
    }
}
