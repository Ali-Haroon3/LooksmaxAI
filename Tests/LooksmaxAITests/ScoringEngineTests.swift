import XCTest
@testable import LooksmaxAI

final class ScoringEngineTests: XCTestCase {

    private func makeMetrics() -> FaceMetrics {
        FaceMetrics(
            interpupillaryDistance: 0.44,
            midfaceLength: 0.44,
            bizygomaticWidth: 0.9,
            upperFaceHeight: 0.45,
            gonialAngle: 122,
            jawWidth: 0.8,
            faceHeight: 1.4,
            leftCanthalTilt: 6,
            rightCanthalTilt: 6,
            eyeSpacing: 0.3,
            browRidgeProminence: 0.6,
            noseLength: 0.3,
            noseWidth: 0.18,
            nasalBridgeHeight: 0.1,
            lipWidth: 0.29,
            upperLipHeight: 0.05,
            lowerLipHeight: 0.06,
            mouthToJawDistance: 0.2,
            eyeSymmetryScore: 0.95,
            jawSymmetryScore: 0.92,
            overallSymmetryScore: 0.93
        )
    }

    func testOverallScoreIsClampedToValidRange() {
        let result = ScoringEngine.calculateScores(from: makeMetrics(), userStats: UserStats())
        XCTAssertGreaterThanOrEqual(result.overallPSLScore, 1.0)
        XCTAssertLessThanOrEqual(result.overallPSLScore, 10.0)
    }

    func testPotentialMaxIsAtLeastCurrentAndCapped() {
        let result = ScoringEngine.calculateScores(from: makeMetrics(), userStats: UserStats())
        XCTAssertGreaterThanOrEqual(result.potentialMaxScore, result.overallPSLScore)
        XCTAssertLessThanOrEqual(result.potentialMaxScore, 9.5)
    }

    func testRegionScoresRollUpWithCorrectWeights() {
        let result = ScoringEngine.calculateScores(from: makeMetrics(), userStats: UserStats())
        let regions = result.regionScores
        let expected = (regions.eyeAreaScore * 0.30)
            + (regions.boneStructureScore * 0.30)
            + (regions.symmetryScore * 0.20)
            + (regions.softmaxBodyScore * 0.20)
        XCTAssertEqual(regions.overallScore, expected, accuracy: 0.0001)
    }

    func testStrongSymmetryScoresHigherThanWeakSymmetry() {
        let strong = makeMetrics()
        let weak = makeMetrics()
        weak.eyeSymmetryScore = 0.4
        weak.jawSymmetryScore = 0.4
        weak.overallSymmetryScore = 0.4

        let strongResult = ScoringEngine.calculateScores(from: strong, userStats: UserStats())
        let weakResult = ScoringEngine.calculateScores(from: weak, userStats: UserStats())
        XCTAssertGreaterThan(strongResult.symmetry.total, weakResult.symmetry.total)
    }

    func testRecommendationsSortedByPriority() {
        // Force low scores so multiple recommendations are generated.
        let metrics = makeMetrics()
        metrics.gonialAngle = 160          // weak jaw → jawline recs
        metrics.leftCanthalTilt = -5
        metrics.rightCanthalTilt = -5      // negative tilt → eye recs
        let stats = UserStats(heightCm: 175, weightKg: 110)  // high BMI → fitness recs

        let result = ScoringEngine.calculateScores(from: metrics, userStats: stats)
        let recs = ScoringEngine.generateRecommendations(from: result)

        XCTAssertFalse(recs.isEmpty)
        for index in 1..<recs.count {
            XCTAssertLessThanOrEqual(recs[index - 1].priority, recs[index].priority)
        }
    }
}
