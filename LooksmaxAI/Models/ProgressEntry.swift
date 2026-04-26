import Foundation

/// A single point in a metric's progression over time.
/// Derived from `ScanHistory` records rather than persisted directly —
/// the scan log is the source of truth for how a metric evolves.
struct ProgressEntry: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let value: Double

    init(id: UUID = UUID(), date: Date, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}

/// Which tracked metric a progress series represents.
enum TrackedMetric: String, CaseIterable, Identifiable {
    case overall = "Overall PSL"
    case eyeArea = "Eye Area"
    case boneStructure = "Bone Structure"
    case symmetry = "Symmetry"
    case softmaxBody = "Body / Softmax"

    var id: String { rawValue }

    /// Extract this metric's value from a scan record.
    func value(from scan: ScanHistory) -> Double {
        switch self {
        case .overall: return scan.overallPSLScore
        case .eyeArea: return scan.eyeAreaScore
        case .boneStructure: return scan.boneStructureScore
        case .symmetry: return scan.symmetryScore
        case .softmaxBody: return scan.softmaxBodyScore
        }
    }

    var systemImage: String {
        switch self {
        case .overall: return "chart.line.uptrend.xyaxis"
        case .eyeArea: return "eye"
        case .boneStructure: return "face.smiling"
        case .symmetry: return "square.split.2x1"
        case .softmaxBody: return "figure.walk"
        }
    }
}

/// Direction of change between two points in a series.
enum TrendDirection {
    case up
    case down
    case flat

    var systemImage: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
}
