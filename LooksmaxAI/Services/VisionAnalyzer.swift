import Foundation
import Vision
import UIKit
import CoreImage

/// VisionAnalyzer: Processes images using Apple Vision framework
/// to extract facial landmarks and calculate metrics
@MainActor
final class VisionAnalyzer {

    // MARK: - Singleton

    static let shared = VisionAnalyzer()
    private init() {}

    // MARK: - Analysis Error

    enum AnalysisError: LocalizedError {
        case noFaceDetected
        case multipleFacesDetected(count: Int)
        case landmarksNotAvailable
        case imageConversionFailed
        case analysisTimeout

        var errorDescription: String? {
            switch self {
            case .noFaceDetected:
                return "No face detected. Please ensure your face is clearly visible."
            case .multipleFacesDetected(let count):
                return "Multiple faces detected (\(count)). Please ensure only one face is in frame."
            case .landmarksNotAvailable:
                return "Could not extract facial landmarks. Try better lighting."
            case .imageConversionFailed:
                return "Failed to process image."
            case .analysisTimeout:
                return "Analysis took too long. Please try again."
            }
        }
    }

    // MARK: - Main Analysis Function

    /// Analyze a face image and extract metrics
    /// - Parameter image: UIImage containing a face
    /// - Returns: FaceMetrics with all calculated values
    func analyzeFace(_ image: UIImage) throws -> FaceMetrics {
        guard let cgImage = image.cgImage else {
            throw AnalysisError.imageConversionFailed
        }

        // Perform face detection with landmarks
        let observations = try detectFaceLandmarks(in: cgImage)

        // Validate single face
        guard !observations.isEmpty else {
            throw AnalysisError.noFaceDetected
        }

        guard observations.count == 1 else {
            throw AnalysisError.multipleFacesDetected(count: observations.count)
        }

        let observation = observations[0]

        guard let landmarks = observation.landmarks else {
            throw AnalysisError.landmarksNotAvailable
        }

        // Extract metrics from landmarks
        let metrics = extractMetrics(
            from: landmarks,
            boundingBox: observation.boundingBox,
            imageSize: CGSize(width: cgImage.width, height: cgImage.height)
        )

        return metrics
    }

    // MARK: - Face Detection

    private nonisolated func detectFaceLandmarks(in cgImage: CGImage) throws -> [VNFaceObservation] {
        let request = VNDetectFaceLandmarksRequest()
        request.revision = VNDetectFaceLandmarksRequestRevision3

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        return request.results ?? []
    }

    // MARK: - Metrics Extraction

    private func extractMetrics(
        from landmarks: VNFaceLandmarks2D,
        boundingBox: CGRect,
        imageSize: CGSize
    ) -> FaceMetrics {
        // Convert bounding box to image coordinates
        let boundingBoxInImage = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )

        // Extract key points
        guard let keyPoints = FaceMath.extractKeyPoints(
            from: landmarks,
            in: boundingBoxInImage
        ) else {
            return FaceMetrics()  // Return default metrics
        }

        // Calculate all metrics
        let midfaceRatio = FaceMath.calculateMidfaceRatio(
            leftPupil: keyPoints.leftPupil,
            rightPupil: keyPoints.rightPupil,
            upperLip: keyPoints.upperLipCenter
        )

        let fwhr = FaceMath.calculateFWHR(
            leftCheekbone: keyPoints.leftCheekbone,
            rightCheekbone: keyPoints.rightCheekbone,
            browCenter: keyPoints.browCenter,
            upperLip: keyPoints.upperLipCenter
        )

        let leftCanthalTilt = FaceMath.calculateCanthalTilt(
            innerCanthus: keyPoints.leftInnerCanthus,
            outerCanthus: keyPoints.leftOuterCanthus
        )

        let rightCanthalTilt = FaceMath.calculateCanthalTilt(
            innerCanthus: keyPoints.rightInnerCanthus,
            outerCanthus: keyPoints.rightOuterCanthus
        )

        let gonialAngle = FaceMath.calculateGonialAngle(
            earPoint: keyPoints.leftCheekbone,  // Approximation
            gonion: keyPoints.leftGonion,
            chinPoint: keyPoints.chin
        )

        // Calculate symmetry
        let leftEyePoints = [keyPoints.leftInnerCanthus, keyPoints.leftOuterCanthus, keyPoints.leftPupil]
        let rightEyePoints = [keyPoints.rightInnerCanthus, keyPoints.rightOuterCanthus, keyPoints.rightPupil]

        let eyeSymmetry = FaceMath.calculateSymmetry(
            leftPoints: leftEyePoints,
            rightPoints: rightEyePoints,
            centerLine: keyPoints.centerX
        )

        let jawSymmetry = FaceMath.calculateSymmetry(
            leftPoints: [keyPoints.leftGonion],
            rightPoints: [keyPoints.rightGonion],
            centerLine: keyPoints.centerX
        )

        // Overall symmetry from face contour
        let contourCount = keyPoints.faceContour.count
        let leftContour = Array(keyPoints.faceContour.prefix(contourCount / 2))
        let rightContour = Array(keyPoints.faceContour.suffix(contourCount / 2).reversed())
        let overallSymmetry = FaceMath.calculateSymmetry(
            leftPoints: leftContour,
            rightPoints: rightContour,
            centerLine: keyPoints.centerX
        )

        // Calculate IPD ratio
        let ipdRatio = FaceMath.calculateIPDRatio(
            leftPupil: keyPoints.leftPupil,
            rightPupil: keyPoints.rightPupil,
            faceWidth: keyPoints.faceWidth
        )

        // Calculate nose metrics
        let noseLength = FaceMath.euclideanDistance(
            from: keyPoints.noseTop,
            to: keyPoints.noseTip
        )

        // Calculate brow ridge prominence (estimated from brow-eye distance)
        let browToEye = abs(keyPoints.browCenter.y - keyPoints.leftPupil.y)
        let browRidgeProminence = min(1.0, browToEye / 30.0)  // Normalize

        // Create metrics object
        return FaceMetrics(
            interpupillaryDistance: ipdRatio,
            midfaceLength: midfaceRatio * keyPoints.ipd,  // Store actual midface length
            bizygomaticWidth: keyPoints.faceWidth,
            upperFaceHeight: abs(keyPoints.browCenter.y - keyPoints.upperLipCenter.y),
            gonialAngle: gonialAngle,
            jawWidth: FaceMath.euclideanDistance(from: keyPoints.leftGonion, to: keyPoints.rightGonion),
            faceHeight: abs(keyPoints.browCenter.y - keyPoints.chin.y),
            leftCanthalTilt: leftCanthalTilt,
            rightCanthalTilt: rightCanthalTilt,
            eyeSpacing: FaceMath.euclideanDistance(from: keyPoints.leftInnerCanthus, to: keyPoints.rightInnerCanthus),
            browRidgeProminence: browRidgeProminence,
            noseLength: noseLength,
            noseWidth: 0,  // Would need additional landmarks
            nasalBridgeHeight: 0,
            lipWidth: 0,
            upperLipHeight: 0,
            lowerLipHeight: 0,
            mouthToJawDistance: abs(keyPoints.upperLipCenter.y - keyPoints.chin.y),
            eyeSymmetryScore: eyeSymmetry,
            jawSymmetryScore: jawSymmetry,
            overallSymmetryScore: overallSymmetry
        )
    }

    // MARK: - Face Quality Check

    /// Check if image quality is suitable for analysis
    func checkImageQuality(_ image: UIImage) -> ImageQualityResult {
        guard let cgImage = image.cgImage else {
            return ImageQualityResult(isAcceptable: false, issues: ["Invalid image format"])
        }

        var issues: [String] = []

        // Check resolution
        if cgImage.width < 640 || cgImage.height < 480 {
            issues.append("Image resolution too low")
        }

        // Check brightness using Core Image
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent

        // Simple brightness check via average pixel values
        let filter = CIFilter(name: "CIAreaAverage")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        if let outputImage = filter?.outputImage {
            var bitmap = [UInt8](repeating: 0, count: 4)
            let context = CIContext(options: [.workingColorSpace: NSNull()])
            context.render(
                outputImage,
                toBitmap: &bitmap,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: nil
            )

            let brightness = (Float(bitmap[0]) + Float(bitmap[1]) + Float(bitmap[2])) / (3 * 255)

            if brightness < 0.2 {
                issues.append("Image too dark - improve lighting")
            } else if brightness > 0.9 {
                issues.append("Image too bright - reduce exposure")
            }
        }

        // Try face detection
        do {
            let observations = try detectFaceLandmarks(in: cgImage)
            if observations.isEmpty {
                issues.append("No face detected")
            } else if observations.count > 1 {
                issues.append("Multiple faces detected")
            } else {
                // Check face size in frame
                let face = observations[0]
                let faceArea = face.boundingBox.width * face.boundingBox.height
                if faceArea < 0.1 {
                    issues.append("Face too small - move closer")
                } else if faceArea > 0.8 {
                    issues.append("Face too close - move back")
                }

                // Check if face is centered
                let faceCenterX = face.boundingBox.midX
                let faceCenterY = face.boundingBox.midY
                if abs(faceCenterX - 0.5) > 0.2 || abs(faceCenterY - 0.5) > 0.25 {
                    issues.append("Center face in frame")
                }
            }
        } catch {
            issues.append("Face detection failed")
        }

        return ImageQualityResult(
            isAcceptable: issues.isEmpty,
            issues: issues
        )
    }
}

// MARK: - Supporting Types

struct ImageQualityResult {
    let isAcceptable: Bool
    let issues: [String]

    var feedback: String {
        if isAcceptable {
            return "Ready to scan"
        }
        return issues.joined(separator: "\n")
    }
}

// MARK: - Debug Extensions

extension VisionAnalyzer {

    /// Generate debug visualization of landmarks
    func generateLandmarkOverlay(
        for image: UIImage,
        observation: VNFaceObservation
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let renderer = UIGraphicsImageRenderer(size: imageSize)

        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)

            // Setup drawing
            context.cgContext.setStrokeColor(UIColor.cyan.cgColor)
            context.cgContext.setLineWidth(2)

            // Convert bounding box
            let boundingBox = observation.boundingBox
            let rect = CGRect(
                x: boundingBox.origin.x * imageSize.width,
                y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
                width: boundingBox.width * imageSize.width,
                height: boundingBox.height * imageSize.height
            )

            // Draw bounding box
            context.cgContext.stroke(rect)

            // Draw landmarks if available
            if let landmarks = observation.landmarks {
                drawLandmarkRegion(landmarks.leftEye, in: rect, context: context)
                drawLandmarkRegion(landmarks.rightEye, in: rect, context: context)
                drawLandmarkRegion(landmarks.nose, in: rect, context: context)
                drawLandmarkRegion(landmarks.outerLips, in: rect, context: context)
                drawLandmarkRegion(landmarks.faceContour, in: rect, context: context)
            }
        }
    }

    private func drawLandmarkRegion(
        _ region: VNFaceLandmarkRegion2D?,
        in rect: CGRect,
        context: UIGraphicsImageRendererContext
    ) {
        guard let region = region else { return }

        context.cgContext.setFillColor(UIColor.cyan.cgColor)

        for point in region.normalizedPoints {
            let x = rect.origin.x + point.x * rect.width
            let y = rect.origin.y + (1 - point.y) * rect.height
            let dotRect = CGRect(x: x - 2, y: y - 2, width: 4, height: 4)
            context.cgContext.fillEllipse(in: dotRect)
        }
    }
}
