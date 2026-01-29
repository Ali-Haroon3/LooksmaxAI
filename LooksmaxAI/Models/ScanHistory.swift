import Foundation
import SwiftData

/// Represents a complete scan session with scores and recommendations
@Model
final class ScanHistory {
    @Attribute(.unique) var id: UUID
    var scannedAt: Date

    // Scores (1-10 PSL Scale)
    var overallPSLScore: Double
    var potentialMaxScore: Double  // What they could achieve

    // Region Breakdown
    var eyeAreaScore: Double
    var boneStructureScore: Double
    var symmetryScore: Double
    var softmaxBodyScore: Double

    // Sub-metrics for detailed breakdown
    var canthalTiltScore: Double
    var ipdScore: Double
    var browRidgeScore: Double
    var fwhrScore: Double
    var gonialAngleScore: Double
    var cheekboneScore: Double
    var bmiScore: Double
    var waistToShoulderScore: Double
    var skinTextureScore: Double

    // Image Data
    @Attribute(.externalStorage) var scanImageData: Data?

    // Relationships
    var userStats: UserStats?

    @Relationship(deleteRule: .cascade)
    var faceMetrics: FaceMetrics?

    @Relationship(deleteRule: .cascade)
    var recommendations: [Recommendation] = []

    init(
        overallPSLScore: Double = 5.0,
        potentialMaxScore: Double = 7.0,
        eyeAreaScore: Double = 5.0,
        boneStructureScore: Double = 5.0,
        symmetryScore: Double = 5.0,
        softmaxBodyScore: Double = 5.0,
        canthalTiltScore: Double = 5.0,
        ipdScore: Double = 5.0,
        browRidgeScore: Double = 5.0,
        fwhrScore: Double = 5.0,
        gonialAngleScore: Double = 5.0,
        cheekboneScore: Double = 5.0,
        bmiScore: Double = 5.0,
        waistToShoulderScore: Double = 5.0,
        skinTextureScore: Double = 5.0
    ) {
        self.id = UUID()
        self.scannedAt = Date()
        self.overallPSLScore = overallPSLScore
        self.potentialMaxScore = potentialMaxScore
        self.eyeAreaScore = eyeAreaScore
        self.boneStructureScore = boneStructureScore
        self.symmetryScore = symmetryScore
        self.softmaxBodyScore = softmaxBodyScore
        self.canthalTiltScore = canthalTiltScore
        self.ipdScore = ipdScore
        self.browRidgeScore = browRidgeScore
        self.fwhrScore = fwhrScore
        self.gonialAngleScore = gonialAngleScore
        self.cheekboneScore = cheekboneScore
        self.bmiScore = bmiScore
        self.waistToShoulderScore = waistToShoulderScore
        self.skinTextureScore = skinTextureScore
    }

    // Computed Properties
    var scoreCategory: ScoreCategory {
        switch overallPSLScore {
        case 0..<3: return .belowAverage
        case 3..<5: return .average
        case 5..<7: return .aboveAverage
        case 7..<8.5: return .attractive
        default: return .modelTier
        }
    }

    var improvementPotential: Double {
        return potentialMaxScore - overallPSLScore
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scannedAt)
    }
}

// MARK: - Score Category

enum ScoreCategory: String, Codable {
    case belowAverage = "Below Average"
    case average = "Average"
    case aboveAverage = "Above Average"
    case attractive = "Attractive"
    case modelTier = "Model Tier"

    var description: String {
        switch self {
        case .belowAverage:
            return "Significant room for improvement with softmaxxing"
        case .average:
            return "Average appearance with good improvement potential"
        case .aboveAverage:
            return "Above average - fine-tuning will yield results"
        case .attractive:
            return "Attractive - optimization for marginal gains"
        case .modelTier:
            return "Elite tier - maintenance focused"
        }
    }

    var color: String {
        switch self {
        case .belowAverage: return "red"
        case .average: return "orange"
        case .aboveAverage: return "yellow"
        case .attractive: return "cyan"
        case .modelTier: return "purple"
        }
    }
}
