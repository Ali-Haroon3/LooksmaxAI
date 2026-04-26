import Foundation

/// Computes progression, trends, and moving averages for tracked metrics
/// from a user's scan history. Pure functions — no persistence side effects.
enum ProgressTracker {

    // MARK: - Series Building

    /// Build an ordered progress series for a given metric.
    /// - Parameters:
    ///   - scans: Scan history (any order).
    ///   - metric: The metric to extract.
    /// - Returns: Entries sorted oldest → newest.
    static func series(from scans: [ScanHistory], metric: TrackedMetric) -> [ProgressEntry] {
        scans
            .sorted { $0.scannedAt < $1.scannedAt }
            .map { ProgressEntry(date: $0.scannedAt, value: metric.value(from: $0)) }
    }

    // MARK: - Trend Analysis

    /// Net change between the earliest and latest entry in a series.
    static func netChange(_ series: [ProgressEntry]) -> Double {
        guard let first = series.first, let last = series.last else { return 0 }
        return last.value - first.value
    }

    /// Direction of the most recent change (last two entries).
    static func latestDirection(_ series: [ProgressEntry], epsilon: Double = 0.05) -> TrendDirection {
        guard series.count >= 2 else { return .flat }
        let delta = series[series.count - 1].value - series[series.count - 2].value
        if delta > epsilon { return .up }
        if delta < -epsilon { return .down }
        return .flat
    }

    /// Simple linear-regression slope (per day) over the series.
    /// Useful for describing long-run momentum rather than day-to-day noise.
    static func slopePerDay(_ series: [ProgressEntry]) -> Double {
        guard series.count >= 2, let start = series.first?.date else { return 0 }

        // x = days since first entry, y = value
        let points: [(x: Double, y: Double)] = series.map {
            let days = $0.date.timeIntervalSince(start) / 86_400.0
            return (x: days, y: $0.value)
        }

        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumXX = points.reduce(0) { $0 + $1.x * $1.x }

        let denominator = (n * sumXX) - (sumX * sumX)
        guard abs(denominator) > 1e-9 else { return 0 }

        return ((n * sumXY) - (sumX * sumY)) / denominator
    }

    // MARK: - Smoothing

    /// Trailing simple moving average with the given window size.
    static func movingAverage(_ series: [ProgressEntry], window: Int = 3) -> [ProgressEntry] {
        guard window > 1, series.count >= window else { return series }

        var smoothed: [ProgressEntry] = []
        for index in series.indices {
            let lower = max(0, index - window + 1)
            let slice = series[lower...index]
            let average = slice.reduce(0) { $0 + $1.value } / Double(slice.count)
            smoothed.append(ProgressEntry(date: series[index].date, value: average))
        }
        return smoothed
    }

    // MARK: - Summary

    /// A human-facing summary of a metric's progression.
    struct Summary {
        let metric: TrackedMetric
        let current: Double
        let best: Double
        let netChange: Double
        let direction: TrendDirection
        let sampleCount: Int
    }

    static func summarize(_ scans: [ScanHistory], metric: TrackedMetric) -> Summary {
        let series = series(from: scans, metric: metric)
        return Summary(
            metric: metric,
            current: series.last?.value ?? 0,
            best: series.map(\.value).max() ?? 0,
            netChange: netChange(series),
            direction: latestDirection(series),
            sampleCount: series.count
        )
    }
}
