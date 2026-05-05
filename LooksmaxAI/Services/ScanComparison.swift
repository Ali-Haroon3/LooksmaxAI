import Foundation

/// Computes a side-by-side, per-metric diff between two scans (typically the
/// earliest "before" and latest "after").
enum ScanComparison {

    /// One metric's before/after values and the delta between them.
    struct MetricDelta: Identifiable {
        let id = UUID()
        let label: String
        let before: Double
        let after: Double

        var delta: Double { after - before }

        var direction: TrendDirection {
            if delta > 0.05 { return .up }
            if delta < -0.05 { return .down }
            return .flat
        }

        var percentChange: Double {
            guard before != 0 else { return 0 }
            return (delta / before) * 100
        }
    }

    struct Result {
        let beforeDate: Date
        let afterDate: Date
        let overallBefore: Double
        let overallAfter: Double
        let deltas: [MetricDelta]

        var overallDelta: Double { overallAfter - overallBefore }

        /// The single most-improved metric, if any improved.
        var biggestGain: MetricDelta? {
            deltas.filter { $0.delta > 0 }.max { $0.delta < $1.delta }
        }

        /// The metric that regressed the most, if any.
        var biggestDrop: MetricDelta? {
            deltas.filter { $0.delta < 0 }.min { $0.delta < $1.delta }
        }

        var daysBetween: Int {
            let interval = afterDate.timeIntervalSince(beforeDate)
            return max(0, Int(interval / 86_400.0))
        }
    }

    /// Build a comparison between two scans. Order-independent — the earlier
    /// scan is always treated as "before".
    static func compare(_ a: ScanHistory, _ b: ScanHistory) -> Result {
        let before = a.scannedAt <= b.scannedAt ? a : b
        let after = a.scannedAt <= b.scannedAt ? b : a

        let deltas: [MetricDelta] = [
            MetricDelta(label: "Eye Area", before: before.eyeAreaScore, after: after.eyeAreaScore),
            MetricDelta(label: "Bone Structure", before: before.boneStructureScore, after: after.boneStructureScore),
            MetricDelta(label: "Symmetry", before: before.symmetryScore, after: after.symmetryScore),
            MetricDelta(label: "Body / Softmax", before: before.softmaxBodyScore, after: after.softmaxBodyScore)
        ]

        return Result(
            beforeDate: before.scannedAt,
            afterDate: after.scannedAt,
            overallBefore: before.overallPSLScore,
            overallAfter: after.overallPSLScore,
            deltas: deltas
        )
    }

    /// Convenience: compare the earliest and latest scans in a collection.
    static func compareFirstAndLast(_ scans: [ScanHistory]) -> Result? {
        let sorted = scans.sorted { $0.scannedAt < $1.scannedAt }
        guard let first = sorted.first, let last = sorted.last, first.id != last.id else {
            return nil
        }
        return compare(first, last)
    }
}
