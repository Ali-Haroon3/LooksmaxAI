import Foundation
import CoreGraphics

/// Golden-ratio ("phi mask") facial harmony analysis.
///
/// Classical aesthetic canons hold that many facial proportions cluster around
/// φ ≈ 1.618. This utility scores how closely a set of measured proportions
/// matches those targets and produces an overall harmony percentage.
enum GoldenRatio {

    /// The golden ratio, φ.
    static let phi: Double = 1.6180339887498949

    // MARK: - Proportion Definitions

    /// A single proportion compared against a golden-ratio-derived target.
    struct Proportion: Identifiable {
        let id = UUID()
        let name: String
        let measured: Double
        let target: Double

        /// How closely the measured value matches the target, 0...1.
        var harmony: Double {
            guard target > 0 else { return 0 }
            let deviation = abs(measured - target) / target
            // Full marks within ~4% deviation, decaying to 0 near 40%.
            return max(0, min(1, 1 - deviation / 0.40))
        }

        var percentage: Int { Int((harmony * 100).rounded()) }
    }

    // MARK: - Analysis

    struct HarmonyReport {
        let proportions: [Proportion]

        /// Mean harmony across all proportions, expressed 0...1.
        var overallHarmony: Double {
            guard !proportions.isEmpty else { return 0 }
            return proportions.reduce(0) { $0 + $1.harmony } / Double(proportions.count)
        }

        var overallPercentage: Int { Int((overallHarmony * 100).rounded()) }

        /// The proportion furthest from its target — the biggest opportunity.
        var weakestLink: Proportion? {
            proportions.min { $0.harmony < $1.harmony }
        }
    }

    /// Build a harmony report from measured facial metrics.
    ///
    /// Targets are expressed as ratios that ideally approach φ or its
    /// reciprocal, following common facial-canon references.
    static func analyze(_ metrics: FaceMetrics) -> HarmonyReport {
        var proportions: [Proportion] = []

        // Face height to width should approach φ.
        if metrics.bizygomaticWidth > 0 {
            proportions.append(Proportion(
                name: "Face Height : Width",
                measured: metrics.faceHeight / metrics.bizygomaticWidth,
                target: phi
            ))
        }

        // Mouth width to nose width often approaches φ.
        if metrics.noseWidth > 0 {
            proportions.append(Proportion(
                name: "Mouth : Nose Width",
                measured: metrics.lipWidth / metrics.noseWidth,
                target: phi
            ))
        }

        // Midface ratio targets ~1.0 (balanced), not φ.
        if metrics.interpupillaryDistance > 0 {
            proportions.append(Proportion(
                name: "Midface Balance",
                measured: metrics.midfaceRatio,
                target: 1.0
            ))
        }

        // Nose length to lip height sits near φ in canonical masks.
        let lipHeight = metrics.upperLipHeight + metrics.lowerLipHeight
        if lipHeight > 0 {
            proportions.append(Proportion(
                name: "Nose : Lip Height",
                measured: metrics.noseLength / lipHeight,
                target: phi
            ))
        }

        return HarmonyReport(proportions: proportions)
    }

    /// Segment a length into its golden-ratio major/minor parts.
    /// Useful for drawing phi-grid overlays.
    static func goldenSegments(of length: CGFloat) -> (major: CGFloat, minor: CGFloat) {
        let major = length / CGFloat(phi)
        return (major: major, minor: length - major)
    }
}
