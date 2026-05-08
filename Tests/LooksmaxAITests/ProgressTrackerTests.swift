import XCTest
@testable import LooksmaxAI

final class ProgressTrackerTests: XCTestCase {

    /// Build a scan with a specific date and overall score.
    private func scan(day: Int, overall: Double) -> ScanHistory {
        let scan = ScanHistory(overallPSLScore: overall)
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = day
        scan.scannedAt = Calendar.current.date(from: components) ?? Date()
        return scan
    }

    func testSeriesIsSortedOldestToNewest() {
        let scans = [scan(day: 3, overall: 7), scan(day: 1, overall: 5), scan(day: 2, overall: 6)]
        let series = ProgressTracker.series(from: scans, metric: .overall)
        XCTAssertEqual(series.map(\.value), [5, 6, 7])
    }

    func testNetChange() {
        let scans = [scan(day: 1, overall: 5), scan(day: 2, overall: 6), scan(day: 3, overall: 7)]
        let series = ProgressTracker.series(from: scans, metric: .overall)
        XCTAssertEqual(ProgressTracker.netChange(series), 2.0, accuracy: 0.0001)
    }

    func testLatestDirectionUp() {
        let scans = [scan(day: 1, overall: 6), scan(day: 2, overall: 6.5)]
        let series = ProgressTracker.series(from: scans, metric: .overall)
        XCTAssertEqual(ProgressTracker.latestDirection(series), .up)
    }

    func testLatestDirectionFlatWithinEpsilon() {
        let scans = [scan(day: 1, overall: 6.0), scan(day: 2, overall: 6.02)]
        let series = ProgressTracker.series(from: scans, metric: .overall)
        XCTAssertEqual(ProgressTracker.latestDirection(series), .flat)
    }

    func testSlopePerDayIsPositiveForRisingScores() {
        let scans = [scan(day: 1, overall: 5), scan(day: 2, overall: 6), scan(day: 3, overall: 7)]
        let series = ProgressTracker.series(from: scans, metric: .overall)
        XCTAssertEqual(ProgressTracker.slopePerDay(series), 1.0, accuracy: 0.01)
    }

    func testMovingAverageSmoothsTrailingWindow() {
        let scans = [scan(day: 1, overall: 5), scan(day: 2, overall: 6), scan(day: 3, overall: 7)]
        let series = ProgressTracker.series(from: scans, metric: .overall)
        let smoothed = ProgressTracker.movingAverage(series, window: 3)
        XCTAssertEqual(smoothed.last?.value ?? 0, 6.0, accuracy: 0.0001)
    }

    func testSummaryReportsBestAndSampleCount() {
        let scans = [scan(day: 1, overall: 5), scan(day: 2, overall: 8), scan(day: 3, overall: 7)]
        let summary = ProgressTracker.summarize(scans, metric: .overall)
        XCTAssertEqual(summary.best, 8.0, accuracy: 0.0001)
        XCTAssertEqual(summary.current, 7.0, accuracy: 0.0001)
        XCTAssertEqual(summary.sampleCount, 3)
    }
}
