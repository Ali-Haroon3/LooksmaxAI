import Foundation
import Vision
import CoreGraphics

/// FaceMath: Mathematical utility for facial landmark analysis
/// Uses VNFaceLandmarks2D coordinates to calculate facial ratios and metrics
final class FaceMath {

    // MARK: - Ideal Targets (Based on Looksmaxxing community standards)

    struct IdealMetrics {
        /// Target Midface Ratio: 1.00 (balanced proportions)
        static let midfaceRatio: Double = 1.0
        static let midfaceRatioRange: ClosedRange<Double> = 0.9...1.1

        /// Target FWHR: 1.9 - 2.2 (masculine ideal)
        static let fwhrMin: Double = 1.9
        static let fwhrMax: Double = 2.2
        static let fwhrRange: ClosedRange<Double> = 1.9...2.2

        /// Ideal Canthal Tilt: Positive (> 0°, ideally 4-8°)
        static let canthalTiltIdeal: Double = 6.0
        static let canthalTiltRange: ClosedRange<Double> = 4.0...10.0

        /// Ideal Gonial Angle: 120-130° for defined jawline
        static let gonialAngleIdeal: Double = 125.0
        static let gonialAngleRange: ClosedRange<Double> = 115.0...130.0

        /// Ideal IPD ratio to face width: 0.42-0.46
        static let ipdRatioRange: ClosedRange<Double> = 0.42...0.46

        /// Ideal BMI for aesthetics
        static let bmiMaleIdeal: ClosedRange<Double> = 22.0...25.0
        static let bmiFemaleIdeal: ClosedRange<Double> = 19.0...23.0

        /// Ideal Waist-to-Shoulder ratio (male)
        static let waistToShoulderMale: Double = 0.6  // V-taper
        static let waistToShoulderFemale: Double = 0.7
    }

    // MARK: - Core Calculations

    /// Calculate Midface Ratio from landmarks
    /// Formula: Midface Length (Pupils to Lips) / Interpupillary Distance (IPD)
    /// - Parameters:
    ///   - leftPupil: Left eye center point
    ///   - rightPupil: Right eye center point
    ///   - upperLip: Center of upper lip
    /// - Returns: Midface ratio (ideal: 1.0)
    static func calculateMidfaceRatio(
        leftPupil: CGPoint,
        rightPupil: CGPoint,
        upperLip: CGPoint
    ) -> Double {
        let ipd = euclideanDistance(from: leftPupil, to: rightPupil)
        guard ipd > 0 else { return 0 }

        // Midface length: vertical distance from pupil line to lips
        let pupilMidpoint = CGPoint(
            x: (leftPupil.x + rightPupil.x) / 2,
            y: (leftPupil.y + rightPupil.y) / 2
        )
        let midfaceLength = abs(pupilMidpoint.y - upperLip.y)

        return midfaceLength / ipd
    }

    /// Calculate Facial Width-to-Height Ratio (FWHR)
    /// Formula: Bizygomatic Width / Upper Face Height
    /// - Parameters:
    ///   - leftCheekbone: Leftmost point of zygomatic arch
    ///   - rightCheekbone: Rightmost point of zygomatic arch
    ///   - browCenter: Center point of brow line
    ///   - upperLip: Center of upper lip
    /// - Returns: FWHR (ideal: 1.9-2.2)
    static func calculateFWHR(
        leftCheekbone: CGPoint,
        rightCheekbone: CGPoint,
        browCenter: CGPoint,
        upperLip: CGPoint
    ) -> Double {
        let bizygomaticWidth = euclideanDistance(from: leftCheekbone, to: rightCheekbone)
        let upperFaceHeight = abs(browCenter.y - upperLip.y)

        guard upperFaceHeight > 0 else { return 0 }
        return bizygomaticWidth / upperFaceHeight
    }

    /// Calculate Canthal Tilt angle
    /// Formula: θ = arctan((y_outer - y_inner) / (x_outer - x_inner))
    /// - Parameters:
    ///   - innerCanthus: Inner corner of eye
    ///   - outerCanthus: Outer corner of eye
    /// - Returns: Tilt angle in degrees (positive = upward tilt)
    static func calculateCanthalTilt(
        innerCanthus: CGPoint,
        outerCanthus: CGPoint
    ) -> Double {
        let deltaX = outerCanthus.x - innerCanthus.x
        let deltaY = outerCanthus.y - innerCanthus.y

        guard deltaX != 0 else { return 0 }

        // Note: In Vision coordinates, Y increases downward
        // Positive tilt means outer corner is HIGHER (smaller Y value)
        let radians = atan2(-deltaY, deltaX)  // Negate Y for correct orientation
        let degrees = radians * 180.0 / .pi

        return degrees
    }

    /// Calculate Gonial Angle (Jaw angle)
    /// Angle between ramus (ascending jaw) and mandible body
    /// - Parameters:
    ///   - earPoint: Point near ear/jaw junction
    ///   - gonion: Angle of jaw (corner)
    ///   - chinPoint: Front of chin/jaw
    /// - Returns: Angle in degrees (ideal: 120-130°)
    static func calculateGonialAngle(
        earPoint: CGPoint,
        gonion: CGPoint,
        chinPoint: CGPoint
    ) -> Double {
        // Vector from gonion to ear
        let v1 = CGPoint(x: earPoint.x - gonion.x, y: earPoint.y - gonion.y)
        // Vector from gonion to chin
        let v2 = CGPoint(x: chinPoint.x - gonion.x, y: chinPoint.y - gonion.y)

        let dotProduct = v1.x * v2.x + v1.y * v2.y
        let magnitude1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let magnitude2 = sqrt(v2.x * v2.x + v2.y * v2.y)

        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }

        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        let clampedCos = max(-1.0, min(1.0, cosAngle))
        let radians = acos(clampedCos)

        return radians * 180.0 / .pi
    }

    /// Calculate symmetry score by comparing mirrored landmark pairs
    /// - Parameters:
    ///   - leftPoints: Array of left-side landmark points
    ///   - rightPoints: Array of corresponding right-side landmarks
    ///   - centerLine: X coordinate of face center
    /// - Returns: Symmetry score (0-1, where 1 = perfect symmetry)
    static func calculateSymmetry(
        leftPoints: [CGPoint],
        rightPoints: [CGPoint],
        centerLine: CGFloat
    ) -> Double {
        guard leftPoints.count == rightPoints.count, !leftPoints.isEmpty else {
            return 1.0  // Default to perfect if no data
        }

        var totalVariance: Double = 0

        for (leftPoint, rightPoint) in zip(leftPoints, rightPoints) {
            // Distance from center line for each point
            let leftDist = abs(leftPoint.x - centerLine)
            let rightDist = abs(rightPoint.x - centerLine)

            // Calculate variance in horizontal distances
            let horizontalVariance = abs(leftDist - rightDist)

            // Calculate variance in vertical positions
            let verticalVariance = abs(leftPoint.y - rightPoint.y)

            totalVariance += horizontalVariance + verticalVariance
        }

        let averageVariance = totalVariance / Double(leftPoints.count)

        // Convert variance to 0-1 score (lower variance = higher score)
        // Using exponential decay for more sensitive scoring
        let symmetryScore = exp(-averageVariance * 10)

        return max(0, min(1, symmetryScore))
    }

    // MARK: - Interpupillary Distance

    /// Calculate IPD ratio (IPD / Face Width)
    static func calculateIPDRatio(
        leftPupil: CGPoint,
        rightPupil: CGPoint,
        faceWidth: CGFloat
    ) -> Double {
        guard faceWidth > 0 else { return 0 }
        let ipd = euclideanDistance(from: leftPupil, to: rightPupil)
        return ipd / faceWidth
    }

    // MARK: - Body Metrics

    /// Calculate BMI score on 1-10 scale
    static func scoreBMI(_ bmi: Double, gender: Gender) -> Double {
        let idealRange = gender == .male ?
            IdealMetrics.bmiMaleIdeal : IdealMetrics.bmiFemaleIdeal

        if idealRange.contains(bmi) {
            return 9.0 + (1.0 - abs(bmi - idealRange.lowerBound) / 3.0)
        }

        let distanceFromIdeal: Double
        if bmi < idealRange.lowerBound {
            distanceFromIdeal = idealRange.lowerBound - bmi
        } else {
            distanceFromIdeal = bmi - idealRange.upperBound
        }

        // Penalty increases exponentially with distance from ideal
        let penalty = pow(distanceFromIdeal / 5.0, 1.5) * 4.0
        return max(1.0, 9.0 - penalty)
    }

    /// Calculate Waist-to-Shoulder score
    static func scoreWaistToShoulder(_ ratio: Double, gender: Gender) -> Double {
        let ideal = gender == .male ?
            IdealMetrics.waistToShoulderMale : IdealMetrics.waistToShoulderFemale

        let deviation = abs(ratio - ideal)

        // Lower ratio is better for males (V-taper)
        if gender == .male && ratio < ideal {
            return min(10, 8.0 + (ideal - ratio) * 10)
        }

        // Score based on deviation from ideal
        let penalty = deviation * 15
        return max(1.0, 10.0 - penalty)
    }

    // MARK: - Helper Functions

    /// Euclidean distance between two points
    static func euclideanDistance(from p1: CGPoint, to p2: CGPoint) -> Double {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Calculate midpoint between two points
    static func midpoint(of p1: CGPoint, and p2: CGPoint) -> CGPoint {
        return CGPoint(
            x: (p1.x + p2.x) / 2,
            y: (p1.y + p2.y) / 2
        )
    }

    /// Normalize a value to 0-1 range
    static func normalize(
        value: Double,
        min: Double,
        max: Double
    ) -> Double {
        guard max > min else { return 0.5 }
        return (value - min) / (max - min)
    }

    /// Convert normalized value to score based on ideal range
    static func scoreFromIdealRange(
        value: Double,
        idealRange: ClosedRange<Double>,
        worstDeviation: Double = 0.5
    ) -> Double {
        if idealRange.contains(value) {
            // Within ideal range: score 8-10
            let rangeCenter = (idealRange.upperBound + idealRange.lowerBound) / 2
            let rangeHalfWidth = (idealRange.upperBound - idealRange.lowerBound) / 2
            let distanceFromCenter = abs(value - rangeCenter) / rangeHalfWidth
            return 10.0 - (distanceFromCenter * 2.0)  // 8-10 range
        }

        // Outside ideal range
        let distanceFromRange: Double
        if value < idealRange.lowerBound {
            distanceFromRange = idealRange.lowerBound - value
        } else {
            distanceFromRange = value - idealRange.upperBound
        }

        let normalizedDistance = distanceFromRange / worstDeviation
        let score = 8.0 - (normalizedDistance * 7.0)  // Can go down to 1

        return max(1.0, min(8.0, score))
    }
}

// MARK: - Vision Landmark Extensions

extension FaceMath {

    /// Extract key points from VNFaceLandmarks2D for analysis
    static func extractKeyPoints(
        from landmarks: VNFaceLandmarks2D,
        in boundingBox: CGRect
    ) -> FacialKeyPoints? {
        guard let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye,
              let nose = landmarks.nose,
              let outerLips = landmarks.outerLips,
              let faceContour = landmarks.faceContour,
              let leftEyebrow = landmarks.leftEyebrow,
              let rightEyebrow = landmarks.rightEyebrow else {
            return nil
        }

        // Convert normalized points to CGPoints
        func normalizedPoints(_ region: VNFaceLandmarkRegion2D) -> [CGPoint] {
            return region.normalizedPoints.map { point in
                CGPoint(
                    x: boundingBox.origin.x + point.x * boundingBox.width,
                    y: boundingBox.origin.y + point.y * boundingBox.height
                )
            }
        }

        let leftEyePoints = normalizedPoints(leftEye)
        let rightEyePoints = normalizedPoints(rightEye)
        let nosePoints = normalizedPoints(nose)
        let lipPoints = normalizedPoints(outerLips)
        let contourPoints = normalizedPoints(faceContour)
        let leftBrowPoints = normalizedPoints(leftEyebrow)
        let rightBrowPoints = normalizedPoints(rightEyebrow)

        // Calculate key anatomical points
        let leftPupil = centerPoint(of: leftEyePoints)
        let rightPupil = centerPoint(of: rightEyePoints)

        // Eye corners (first and last points typically)
        let leftInnerCanthus = leftEyePoints.first ?? leftPupil
        let leftOuterCanthus = leftEyePoints.last ?? leftPupil
        let rightInnerCanthus = rightEyePoints.last ?? rightPupil
        let rightOuterCanthus = rightEyePoints.first ?? rightPupil

        // Lip center
        let upperLipCenter = lipPoints.count > 0 ?
            lipPoints[lipPoints.count / 2] : CGPoint.zero

        // Face contour extremes for cheekbones
        let sortedByX = contourPoints.sorted { $0.x < $1.x }
        let leftCheekbone = sortedByX.first ?? CGPoint.zero
        let rightCheekbone = sortedByX.last ?? CGPoint.zero

        // Jaw points (gonion approximation from contour)
        let jawPoints = contourPoints.prefix(contourPoints.count / 3)
        let leftGonion = jawPoints.first ?? CGPoint.zero
        let rightGonion = Array(jawPoints).last ?? CGPoint.zero
        let chin = contourPoints[contourPoints.count / 2]

        // Brow center
        let browCenter = midpoint(
            of: centerPoint(of: leftBrowPoints),
            and: centerPoint(of: rightBrowPoints)
        )

        return FacialKeyPoints(
            leftPupil: leftPupil,
            rightPupil: rightPupil,
            leftInnerCanthus: leftInnerCanthus,
            leftOuterCanthus: leftOuterCanthus,
            rightInnerCanthus: rightInnerCanthus,
            rightOuterCanthus: rightOuterCanthus,
            upperLipCenter: upperLipCenter,
            leftCheekbone: leftCheekbone,
            rightCheekbone: rightCheekbone,
            leftGonion: leftGonion,
            rightGonion: rightGonion,
            chin: chin,
            browCenter: browCenter,
            noseTop: nosePoints.first ?? CGPoint.zero,
            noseTip: nosePoints.count > 1 ? nosePoints[nosePoints.count - 1] : CGPoint.zero,
            faceContour: contourPoints
        )
    }

    /// Calculate center point of a set of points
    static func centerPoint(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) { result, point in
            CGPoint(x: result.x + point.x, y: result.y + point.y)
        }
        return CGPoint(
            x: sum.x / CGFloat(points.count),
            y: sum.y / CGFloat(points.count)
        )
    }
}

// MARK: - Facial Key Points Structure

struct FacialKeyPoints {
    // Eyes
    let leftPupil: CGPoint
    let rightPupil: CGPoint
    let leftInnerCanthus: CGPoint
    let leftOuterCanthus: CGPoint
    let rightInnerCanthus: CGPoint
    let rightOuterCanthus: CGPoint

    // Lips
    let upperLipCenter: CGPoint

    // Bone Structure
    let leftCheekbone: CGPoint
    let rightCheekbone: CGPoint
    let leftGonion: CGPoint
    let rightGonion: CGPoint
    let chin: CGPoint
    let browCenter: CGPoint

    // Nose
    let noseTop: CGPoint
    let noseTip: CGPoint

    // Full contour for additional analysis
    let faceContour: [CGPoint]

    /// Interpupillary distance
    var ipd: Double {
        FaceMath.euclideanDistance(from: leftPupil, to: rightPupil)
    }

    /// Face width at cheekbones
    var faceWidth: Double {
        FaceMath.euclideanDistance(from: leftCheekbone, to: rightCheekbone)
    }

    /// Face center X coordinate
    var centerX: CGFloat {
        (leftCheekbone.x + rightCheekbone.x) / 2
    }
}
