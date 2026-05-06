import Foundation

/// Produces plain-text and structured summaries of a scan suitable for sharing
/// or exporting. Kept UI-free so it can be unit tested and reused by the share
/// sheet, clipboard, and file export paths.
enum ReportGenerator {

    struct Line {
        let label: String
        let value: String
    }

    /// A structured, presentation-agnostic report.
    struct Report {
        let title: String
        let headlineScore: String
        let category: String
        let lines: [Line]
        let disclaimer: String
    }

    static func makeReport(for scan: ScanHistory) -> Report {
        let lines: [Line] = [
            Line(label: "Eye Area", value: formatted(scan.eyeAreaScore)),
            Line(label: "Bone Structure", value: formatted(scan.boneStructureScore)),
            Line(label: "Symmetry", value: formatted(scan.symmetryScore)),
            Line(label: "Body / Softmax", value: formatted(scan.softmaxBodyScore)),
            Line(label: "Potential", value: formatted(scan.potentialMaxScore))
        ]

        return Report(
            title: "LooksmaxAI Scan",
            headlineScore: formatted(scan.overallPSLScore),
            category: scan.scoreCategory.rawValue,
            lines: lines,
            disclaimer: "For entertainment only. Beauty standards are subjective."
        )
    }

    /// Render a report as shareable plain text.
    static func plainText(for scan: ScanHistory) -> String {
        let report = makeReport(for: scan)
        var output = "\(report.title)\n"
        output += "Overall: \(report.headlineScore) — \(report.category)\n"
        output += String(repeating: "─", count: 24) + "\n"
        for line in report.lines {
            output += "\(line.label.padding(toLength: 18, withPad: " ", startingAt: 0))\(line.value)\n"
        }
        output += String(repeating: "─", count: 24) + "\n"
        output += report.disclaimer
        return output
    }

    private static func formatted(_ score: Double) -> String {
        String(format: "%.1f / 10", score)
    }
}
