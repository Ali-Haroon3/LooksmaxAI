import Foundation
import SwiftData

/// Detailed facial metrics extracted from Vision framework analysis
@Model
final class FaceMetrics {
    @Attribute(.unique) var id: UUID
    var analyzedAt: Date

    // Raw Landmark Distances (normalized 0-1 coordinates)
    var interpupillaryDistance: Double  // IPD
    var midfaceLength: Double           // Pupils to lips vertical distance
    var bizygomaticWidth: Double        // Cheekbone to cheekbone
    var upperFaceHeight: Double         // Brow to upper lip
    var gonialAngle: Double             // Jaw angle in degrees
    var jawWidth: Double                // Lower jaw width
    var faceHeight: Double              // Total face height

    // Eye Measurements
    var leftCanthalTilt: Double         // Left eye tilt angle
    var rightCanthalTilt: Double        // Right eye tilt angle
    var eyeSpacing: Double              // Inner corner to inner corner
    var browRidgeProminence: Double     // Estimated from landmarks

    // Nose Measurements
    var noseLength: Double
    var noseWidth: Double
    var nasalBridgeHeight: Double

    // Mouth/Lips
    var lipWidth: Double
    var upperLipHeight: Double
    var lowerLipHeight: Double
    var mouthToJawDistance: Double

    // Symmetry Metrics (variance between left/right)
    var eyeSymmetryScore: Double        // 0-1, 1 = perfect symmetry
    var jawSymmetryScore: Double
    var overallSymmetryScore: Double

    // Calculated Ratios
    var midfaceRatio: Double {
        guard interpupillaryDistance > 0 else { return 0 }
        return midfaceLength / interpupillaryDistance
    }

    var fwhr: Double {  // Facial Width to Height Ratio
        guard upperFaceHeight > 0 else { return 0 }
        return bizygomaticWidth / upperFaceHeight
    }

    var averageCanthalTilt: Double {
        return (leftCanthalTilt + rightCanthalTilt) / 2.0
    }

    var canthalTiltCategory: CanthalTiltCategory {
        let avg = averageCanthalTilt
        if avg > 5 { return .positive }
        if avg < -3 { return .negative }
        return .neutral
    }

    // Relationship
    @Relationship var scanHistory: ScanHistory?

    init(
        interpupillaryDistance: Double = 0,
        midfaceLength: Double = 0,
        bizygomaticWidth: Double = 0,
        upperFaceHeight: Double = 0,
        gonialAngle: Double = 120,
        jawWidth: Double = 0,
        faceHeight: Double = 0,
        leftCanthalTilt: Double = 0,
        rightCanthalTilt: Double = 0,
        eyeSpacing: Double = 0,
        browRidgeProminence: Double = 0,
        noseLength: Double = 0,
        noseWidth: Double = 0,
        nasalBridgeHeight: Double = 0,
        lipWidth: Double = 0,
        upperLipHeight: Double = 0,
        lowerLipHeight: Double = 0,
        mouthToJawDistance: Double = 0,
        eyeSymmetryScore: Double = 1,
        jawSymmetryScore: Double = 1,
        overallSymmetryScore: Double = 1
    ) {
        self.id = UUID()
        self.analyzedAt = Date()
        self.interpupillaryDistance = interpupillaryDistance
        self.midfaceLength = midfaceLength
        self.bizygomaticWidth = bizygomaticWidth
        self.upperFaceHeight = upperFaceHeight
        self.gonialAngle = gonialAngle
        self.jawWidth = jawWidth
        self.faceHeight = faceHeight
        self.leftCanthalTilt = leftCanthalTilt
        self.rightCanthalTilt = rightCanthalTilt
        self.eyeSpacing = eyeSpacing
        self.browRidgeProminence = browRidgeProminence
        self.noseLength = noseLength
        self.noseWidth = noseWidth
        self.nasalBridgeHeight = nasalBridgeHeight
        self.lipWidth = lipWidth
        self.upperLipHeight = upperLipHeight
        self.lowerLipHeight = lowerLipHeight
        self.mouthToJawDistance = mouthToJawDistance
        self.eyeSymmetryScore = eyeSymmetryScore
        self.jawSymmetryScore = jawSymmetryScore
        self.overallSymmetryScore = overallSymmetryScore
    }
}

// MARK: - Supporting Types

enum CanthalTiltCategory: String, Codable {
    case positive = "Positive (Hunter Eyes)"
    case neutral = "Neutral"
    case negative = "Negative (Droopy)"

    var emoji: String {
        switch self {
        case .positive: return "👁️‍🗨️"
        case .neutral: return "👁️"
        case .negative: return "😔"
        }
    }
}

/// Individual facial region scores
struct FaceRegionScores: Codable {
    var eyeAreaScore: Double      // 30% weight
    var boneStructureScore: Double // 30% weight
    var symmetryScore: Double      // 20% weight
    var softmaxBodyScore: Double   // 20% weight

    var overallScore: Double {
        return (eyeAreaScore * 0.30) +
               (boneStructureScore * 0.30) +
               (symmetryScore * 0.20) +
               (softmaxBodyScore * 0.20)
    }

    static var empty: FaceRegionScores {
        FaceRegionScores(
            eyeAreaScore: 0,
            boneStructureScore: 0,
            symmetryScore: 0,
            softmaxBodyScore: 0
        )
    }
}
