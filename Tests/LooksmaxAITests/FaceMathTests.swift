import XCTest
import CoreGraphics
@testable import LooksmaxAI

final class FaceMathTests: XCTestCase {

    private let accuracy = 0.0001

    func testEuclideanDistance() {
        let d = FaceMath.euclideanDistance(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 3, y: 4))
        XCTAssertEqual(d, 5.0, accuracy: accuracy)
    }

    func testMidpoint() {
        let mid = FaceMath.midpoint(of: CGPoint(x: 0, y: 0), and: CGPoint(x: 2, y: 4))
        XCTAssertEqual(mid.x, 1.0, accuracy: accuracy)
        XCTAssertEqual(mid.y, 2.0, accuracy: accuracy)
    }

    func testNormalizeMidpoint() {
        XCTAssertEqual(FaceMath.normalize(value: 5, min: 0, max: 10), 0.5, accuracy: accuracy)
    }

    func testNormalizeDegenerateRangeReturnsHalf() {
        XCTAssertEqual(FaceMath.normalize(value: 5, min: 3, max: 3), 0.5, accuracy: accuracy)
    }

    func testFWHRIsWidthOverHeight() {
        // Cheekbones 4 apart horizontally; brow-to-lip height of 2 → FWHR 2.0
        let fwhr = FaceMath.calculateFWHR(
            leftCheekbone: CGPoint(x: 0, y: 0),
            rightCheekbone: CGPoint(x: 4, y: 0),
            browCenter: CGPoint(x: 2, y: 0),
            upperLip: CGPoint(x: 2, y: 2)
        )
        XCTAssertEqual(fwhr, 2.0, accuracy: accuracy)
    }

    func testPositiveCanthalTiltWhenOuterCornerIsHigher() {
        // Vision coords: y increases downward, so a smaller outer y = higher corner.
        let tilt = FaceMath.calculateCanthalTilt(
            innerCanthus: CGPoint(x: 0, y: 1),
            outerCanthus: CGPoint(x: 1, y: 0)
        )
        XCTAssertGreaterThan(tilt, 0)
    }

    func testNegativeCanthalTiltWhenOuterCornerIsLower() {
        let tilt = FaceMath.calculateCanthalTilt(
            innerCanthus: CGPoint(x: 0, y: 0),
            outerCanthus: CGPoint(x: 1, y: 1)
        )
        XCTAssertLessThan(tilt, 0)
    }

    func testBMIScoreWithinIdealRangeIsHigh() {
        // Male ideal 22...25; 23.5 → 9.5
        let score = FaceMath.scoreBMI(23.5, gender: .male)
        XCTAssertEqual(score, 9.5, accuracy: 0.01)
    }

    func testBMIScoreFarFromIdealIsPenalized() {
        let ideal = FaceMath.scoreBMI(23.5, gender: .male)
        let obese = FaceMath.scoreBMI(35.0, gender: .male)
        XCTAssertLessThan(obese, ideal)
        XCTAssertGreaterThanOrEqual(obese, 1.0)
    }

    func testGoldenSegmentsSumToWhole() {
        let (major, minor) = GoldenRatio.goldenSegments(of: 100)
        XCTAssertEqual(Double(major + minor), 100, accuracy: 0.001)
        XCTAssertGreaterThan(major, minor)
    }
}
