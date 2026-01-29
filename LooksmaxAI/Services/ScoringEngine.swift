import Foundation

/// ScoringEngine: Converts raw facial metrics and body stats into PSL scores (1-10 scale)
/// Scoring Weights:
/// - Eye Area: 30%
/// - Bone Structure: 30%
/// - Symmetry: 20%
/// - Softmax/Body: 20%
final class ScoringEngine {

    // MARK: - Scoring Weights

    struct Weights {
        static let eyeArea: Double = 0.30
        static let boneStructure: Double = 0.30
        static let symmetry: Double = 0.20
        static let softmaxBody: Double = 0.20
    }

    // MARK: - Main Scoring Function

    /// Calculate comprehensive PSL score from face metrics and user stats
    /// - Parameters:
    ///   - metrics: Analyzed facial metrics
    ///   - userStats: User's body measurements
    /// - Returns: Complete scan result with all scores
    static func calculateScores(
        from metrics: FaceMetrics,
        userStats: UserStats
    ) -> ScanResult {
        // Calculate region scores
        let eyeAreaScore = calculateEyeAreaScore(from: metrics)
        let boneStructureScore = calculateBoneStructureScore(from: metrics)
        let symmetryScore = calculateSymmetryScore(from: metrics)
        let softmaxScore = calculateSoftmaxScore(from: metrics, userStats: userStats)

        // Calculate weighted overall score
        let overallScore = (eyeAreaScore.total * Weights.eyeArea) +
                          (boneStructureScore.total * Weights.boneStructure) +
                          (symmetryScore.total * Weights.symmetry) +
                          (softmaxScore.total * Weights.softmaxBody)

        // Calculate potential max (optimized BMI + skin)
        let potentialMax = calculatePotentialMax(
            currentScore: overallScore,
            bmiScore: softmaxScore.bmiScore,
            skinScore: softmaxScore.skinTextureScore
        )

        return ScanResult(
            overallPSLScore: clampScore(overallScore),
            potentialMaxScore: clampScore(potentialMax),
            eyeArea: eyeAreaScore,
            boneStructure: boneStructureScore,
            symmetry: symmetryScore,
            softmaxBody: softmaxScore
        )
    }

    // MARK: - Eye Area Scoring (30%)

    /// Score eye area: canthal tilt, IPD, brow ridge
    private static func calculateEyeAreaScore(from metrics: FaceMetrics) -> EyeAreaScore {
        // Canthal Tilt Score
        let canthalTiltScore = scoreCanthalTilt(metrics.averageCanthalTilt)

        // IPD Score (ideal ratio ~0.44)
        let ipdScore = scoreIPD(metrics.interpupillaryDistance)

        // Brow Ridge Score
        let browRidgeScore = scoreBrowRidge(metrics.browRidgeProminence)

        // Eye area total (weighted within category)
        let total = (canthalTiltScore * 0.50) +
                   (ipdScore * 0.25) +
                   (browRidgeScore * 0.25)

        return EyeAreaScore(
            total: total,
            canthalTiltScore: canthalTiltScore,
            ipdScore: ipdScore,
            browRidgeScore: browRidgeScore
        )
    }

    private static func scoreCanthalTilt(_ tilt: Double) -> Double {
        // Ideal: +4° to +10° (positive, "hunter eyes")
        // Negative tilt is penalized
        if tilt >= 4 && tilt <= 10 {
            return 9.0 + (1.0 - abs(tilt - 7) / 3.0)  // 9-10 for ideal
        } else if tilt > 0 && tilt < 4 {
            return 7.0 + (tilt / 4.0) * 2.0  // 7-9 for slight positive
        } else if tilt == 0 {
            return 6.0  // Neutral
        } else if tilt > -3 {
            return 4.0 + (3.0 + tilt)  // 4-7 for slight negative
        } else {
            return max(1.0, 4.0 + tilt / 3.0)  // 1-4 for very negative
        }
    }

    private static func scoreIPD(_ ipd: Double) -> Double {
        // Score based on IPD proportion (normalized value expected)
        // Ideal IPD ratio: 0.42-0.46 of face width
        let idealRange = FaceMath.IdealMetrics.ipdRatioRange

        if idealRange.contains(ipd) {
            return 8.5 + (1.5 * (1.0 - abs(ipd - 0.44) / 0.02))
        }

        let deviation = ipd < idealRange.lowerBound ?
            idealRange.lowerBound - ipd : ipd - idealRange.upperBound
        return max(1.0, 8.5 - deviation * 30)
    }

    private static func scoreBrowRidge(_ prominence: Double) -> Double {
        // Brow ridge prominence (0-1 scale from analysis)
        // Higher is generally more masculine/desirable
        return min(10, max(1, 5.0 + prominence * 5.0))
    }

    // MARK: - Bone Structure Scoring (30%)

    /// Score bone structure: FWHR, gonial angle, cheekbones
    private static func calculateBoneStructureScore(from metrics: FaceMetrics) -> BoneStructureScore {
        // FWHR Score
        let fwhrScore = scoreFWHR(metrics.fwhr)

        // Gonial Angle Score
        let gonialAngleScore = scoreGonialAngle(metrics.gonialAngle)

        // Cheekbone Prominence Score
        let cheekboneScore = scoreCheekbones(metrics.bizygomaticWidth, faceWidth: metrics.jawWidth)

        // Bone structure total
        let total = (fwhrScore * 0.35) +
                   (gonialAngleScore * 0.35) +
                   (cheekboneScore * 0.30)

        return BoneStructureScore(
            total: total,
            fwhrScore: fwhrScore,
            gonialAngleScore: gonialAngleScore,
            cheekboneScore: cheekboneScore
        )
    }

    private static func scoreFWHR(_ fwhr: Double) -> Double {
        // Ideal: 1.9-2.2
        let idealRange = FaceMath.IdealMetrics.fwhrRange

        if idealRange.contains(fwhr) {
            let center = 2.05
            return 9.0 + (1.0 - abs(fwhr - center) / 0.15)
        }

        let deviation: Double
        if fwhr < idealRange.lowerBound {
            deviation = idealRange.lowerBound - fwhr
        } else {
            deviation = fwhr - idealRange.upperBound
        }

        return max(1.0, 9.0 - deviation * 8)
    }

    private static func scoreGonialAngle(_ angle: Double) -> Double {
        // Ideal: 115°-130° (lower = more defined jaw)
        let idealRange = FaceMath.IdealMetrics.gonialAngleRange

        if idealRange.contains(angle) {
            // Lower within range is slightly better
            let normalizedPosition = (idealRange.upperBound - angle) /
                                    (idealRange.upperBound - idealRange.lowerBound)
            return 8.0 + normalizedPosition * 2.0
        }

        let deviation: Double
        if angle < idealRange.lowerBound {
            deviation = idealRange.lowerBound - angle
            // Very low angle can be too extreme
            return max(1.0, 8.0 - deviation * 0.3)
        } else {
            deviation = angle - idealRange.upperBound
            // High angle = weak jaw
            return max(1.0, 8.0 - deviation * 0.4)
        }
    }

    private static func scoreCheekbones(_ zygoWidth: Double, faceWidth: Double) -> Double {
        // Score based on cheekbone prominence relative to jaw
        guard faceWidth > 0 else { return 5.0 }

        let ratio = zygoWidth / faceWidth
        // Ideal: cheekbones slightly wider than jaw (ratio > 1.0)
        if ratio >= 1.05 && ratio <= 1.20 {
            return 9.0 + (1.0 - abs(ratio - 1.12) / 0.08)
        }

        if ratio < 1.05 {
            return max(1.0, 9.0 - (1.05 - ratio) * 40)
        } else {
            return max(1.0, 9.0 - (ratio - 1.20) * 20)
        }
    }

    // MARK: - Symmetry Scoring (20%)

    /// Score facial symmetry from variance analysis
    private static func calculateSymmetryScore(from metrics: FaceMetrics) -> SymmetryScore {
        // Eye symmetry (most noticeable)
        let eyeScore = metrics.eyeSymmetryScore * 10

        // Jaw symmetry
        let jawScore = metrics.jawSymmetryScore * 10

        // Overall symmetry
        let overallScore = metrics.overallSymmetryScore * 10

        // Weighted symmetry total
        let total = (eyeScore * 0.40) +
                   (jawScore * 0.30) +
                   (overallScore * 0.30)

        return SymmetryScore(
            total: total,
            eyeSymmetryScore: eyeScore,
            jawSymmetryScore: jawScore,
            overallSymmetryScore: overallScore
        )
    }

    // MARK: - Softmax/Body Scoring (20%)

    /// Score body metrics: BMI, waist-to-shoulder, skin texture
    private static func calculateSoftmaxScore(
        from metrics: FaceMetrics,
        userStats: UserStats
    ) -> SoftmaxScore {
        // BMI Score
        let bmiScore = FaceMath.scoreBMI(userStats.bmi, gender: userStats.gender)

        // Waist-to-Shoulder Score
        let waistToShoulderScore = FaceMath.scoreWaistToShoulder(
            userStats.waistToShoulderRatio,
            gender: userStats.gender
        )

        // Skin Texture Score (placeholder - would use ML model in production)
        let skinTextureScore = 7.0  // Default moderate score

        // Softmax total
        let total = (bmiScore * 0.40) +
                   (waistToShoulderScore * 0.35) +
                   (skinTextureScore * 0.25)

        return SoftmaxScore(
            total: total,
            bmiScore: bmiScore,
            waistToShoulderScore: waistToShoulderScore,
            skinTextureScore: skinTextureScore
        )
    }

    // MARK: - Potential Max Calculation

    /// Calculate what score could be achieved with optimized softmax factors
    private static func calculatePotentialMax(
        currentScore: Double,
        bmiScore: Double,
        skinScore: Double
    ) -> Double {
        // Assume optimal BMI (9.5) and skin (9.0) scores
        let optimalBMI = 9.5
        let optimalSkin = 9.0

        // Calculate the improvement potential
        let bmiImprovement = (optimalBMI - bmiScore) * 0.40 * Weights.softmaxBody
        let skinImprovement = (optimalSkin - skinScore) * 0.25 * Weights.softmaxBody

        let potentialMax = currentScore + bmiImprovement + skinImprovement

        // Cap at realistic maximum (few people exceed 9.5)
        return min(9.5, potentialMax)
    }

    // MARK: - Helpers

    private static func clampScore(_ score: Double) -> Double {
        return max(1.0, min(10.0, score))
    }
}

// MARK: - Score Result Types

struct ScanResult {
    let overallPSLScore: Double
    let potentialMaxScore: Double
    let eyeArea: EyeAreaScore
    let boneStructure: BoneStructureScore
    let symmetry: SymmetryScore
    let softmaxBody: SoftmaxScore

    var regionScores: FaceRegionScores {
        FaceRegionScores(
            eyeAreaScore: eyeArea.total,
            boneStructureScore: boneStructure.total,
            symmetryScore: symmetry.total,
            softmaxBodyScore: softmaxBody.total
        )
    }
}

struct EyeAreaScore {
    let total: Double
    let canthalTiltScore: Double
    let ipdScore: Double
    let browRidgeScore: Double
}

struct BoneStructureScore {
    let total: Double
    let fwhrScore: Double
    let gonialAngleScore: Double
    let cheekboneScore: Double
}

struct SymmetryScore {
    let total: Double
    let eyeSymmetryScore: Double
    let jawSymmetryScore: Double
    let overallSymmetryScore: Double
}

struct SoftmaxScore {
    let total: Double
    let bmiScore: Double
    let waistToShoulderScore: Double
    let skinTextureScore: Double
}

// MARK: - Recommendation Generator

extension ScoringEngine {

    /// Generate personalized recommendations based on scores
    static func generateRecommendations(from result: ScanResult) -> [RecommendationData] {
        var recommendations: [RecommendationData] = []

        // Eye Area Recommendations
        if result.eyeArea.canthalTiltScore < 6 {
            recommendations.append(RecommendationData(
                title: "Eyebrow Grooming",
                description: "Shape eyebrows to create visual lift and enhance eye area",
                category: .eyeArea,
                priority: .high,
                targetMetric: "canthalTilt",
                expectedImprovement: 0.3,
                instructions: [
                    "Avoid over-plucking - maintain natural thickness",
                    "Create slight arch at 2/3 point from inner corner",
                    "Trim any overly long hairs",
                    "Consider professional shaping initially"
                ],
                tips: [
                    "Hunter eyes illusion through grooming",
                    "Avoid rounded brow shapes"
                ]
            ))

            recommendations.append(RecommendationData(
                title: "Sleep Optimization",
                description: "Quality sleep reduces eye puffiness and improves eye area",
                category: .sleep,
                priority: .high,
                targetMetric: "canthalTilt",
                expectedImprovement: 0.2,
                instructions: [
                    "Aim for 7-9 hours per night",
                    "Sleep on your back to prevent eye compression",
                    "Use silk pillowcase to reduce friction",
                    "Keep room cool (65-68°F)"
                ],
                tips: [
                    "Consistent sleep schedule is key",
                    "Avoid screens 1 hour before bed"
                ]
            ))
        }

        // Bone Structure Recommendations
        if result.boneStructure.gonialAngleScore < 7 {
            recommendations.append(RecommendationData(
                title: "Mewing Technique",
                description: "Proper tongue posture to enhance jawline definition",
                category: .jawline,
                priority: .critical,
                targetMetric: "gonialAngle",
                expectedImprovement: 0.5,
                instructions: [
                    "Rest entire tongue on roof of mouth",
                    "Teeth should be lightly touching",
                    "Lips closed, breathe through nose",
                    "Maintain posture 24/7 for best results"
                ],
                tips: [
                    "Results take 6-24 months",
                    "Younger individuals see faster changes"
                ]
            ))

            recommendations.append(RecommendationData(
                title: "Chewing Exercises",
                description: "Strengthen masseter muscles for jaw definition",
                category: .jawline,
                priority: .high,
                targetMetric: "gonialAngle",
                expectedImprovement: 0.4,
                instructions: [
                    "Use mastic gum or hard gum",
                    "Chew for 20-30 minutes daily",
                    "Alternate sides evenly",
                    "Start slow to avoid TMJ issues"
                ],
                tips: [
                    "Don't overdo it - rest days important",
                    "Falim gum is popular choice"
                ]
            ))
        }

        // Body/Softmax Recommendations
        if result.softmaxBody.bmiScore < 7 {
            recommendations.append(RecommendationData(
                title: "Body Recomposition",
                description: "Optimize body fat percentage for facial aesthetics",
                category: .fitness,
                priority: .critical,
                targetMetric: "bmi",
                expectedImprovement: 0.8,
                instructions: [
                    "Target 10-15% body fat for men",
                    "Caloric deficit of 300-500 calories",
                    "High protein intake (1g per lb bodyweight)",
                    "Resistance training 3-4x per week"
                ],
                tips: [
                    "Lower body fat reveals facial structure",
                    "Don't cut too aggressively"
                ]
            ))
        }

        if result.softmaxBody.waistToShoulderScore < 7 {
            recommendations.append(RecommendationData(
                title: "V-Taper Development",
                description: "Build shoulder width and reduce waist for ideal proportions",
                category: .fitness,
                priority: .high,
                targetMetric: "waistToShoulder",
                expectedImprovement: 0.5,
                instructions: [
                    "Focus on lateral deltoid development",
                    "Include overhead pressing movements",
                    "Core work for waist tightening",
                    "Lat development for V-shape"
                ],
                tips: [
                    "Lateral raises are key",
                    "Avoid excessive oblique work"
                ]
            ))
        }

        // Skincare (always include)
        if result.softmaxBody.skinTextureScore < 8 {
            recommendations.append(RecommendationData(
                title: "Skincare Protocol",
                description: "Comprehensive routine for clear, healthy skin",
                category: .skincare,
                priority: .medium,
                targetMetric: "skinTexture",
                expectedImprovement: 0.4,
                instructions: [
                    "Cleanser (AM & PM)",
                    "Tretinoin/Retinol (PM)",
                    "Moisturizer (AM & PM)",
                    "SPF 30+ (AM)"
                ],
                tips: [
                    "Start retinoids slowly",
                    "Hydration is key"
                ]
            ))
        }

        // Sort by priority
        return recommendations.sorted { $0.priority < $1.priority }
    }
}

// MARK: - Recommendation Data (for generation)

struct RecommendationData {
    let title: String
    let description: String
    let category: RecommendationCategory
    let priority: Priority
    let targetMetric: String
    let expectedImprovement: Double
    let instructions: [String]
    let tips: [String]

    func toRecommendation() -> Recommendation {
        Recommendation(
            title: title,
            descriptionText: description,
            category: category,
            priority: priority,
            difficulty: .moderate,
            targetMetric: targetMetric,
            expectedImprovement: expectedImprovement,
            instructions: instructions,
            tips: tips
        )
    }
}
