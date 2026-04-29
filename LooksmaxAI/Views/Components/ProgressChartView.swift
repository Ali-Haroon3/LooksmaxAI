import SwiftUI
import Charts

/// Line chart of a tracked metric over time, with an optional smoothed
/// moving-average overlay. Styled to match the app's dark, neon aesthetic.
struct ProgressChartView: View {
    let metric: TrackedMetric
    let series: [ProgressEntry]
    var showMovingAverage: Bool = true

    private var smoothed: [ProgressEntry] {
        ProgressTracker.movingAverage(series, window: 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            header

            if series.isEmpty {
                emptyState
            } else {
                chart
                    .frame(height: 200)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .glassCard()
    }

    private var header: some View {
        HStack {
            Label(metric.rawValue, systemImage: metric.systemImage)
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
            if let current = series.last?.value {
                Text(String(format: "%.1f", current))
                    .font(DesignSystem.Typography.mono(16))
                    .foregroundColor(current.scoreColor)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(series) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Score", entry.value)
                )
                .foregroundStyle(DesignSystem.Colors.accentCyan)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Score", entry.value)
                )
                .foregroundStyle(DesignSystem.Colors.accentCyan)
                .symbolSize(30)
            }

            if showMovingAverage {
                ForEach(smoothed) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Avg", entry.value),
                        series: .value("Series", "avg")
                    )
                    .foregroundStyle(DesignSystem.Colors.accentPurple.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                }
            }
        }
        .chartYScale(domain: 0...10)
        .chartYAxis {
            AxisMarks(values: [0, 2.5, 5, 7.5, 10]) {
                AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel().foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            Text("Run a few scans to see your trend.")
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }
}
