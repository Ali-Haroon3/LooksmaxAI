import Foundation

/// Evaluates the achievement catalog against the user's current state and
/// returns which badges should newly unlock. Stateless; the caller owns
/// persistence of the `Achievement` models.
enum AchievementEngine {

    struct EvaluationResult {
        /// Achievements that transitioned to unlocked during this evaluation.
        let newlyUnlocked: [AchievementCatalog.Definition]
        /// Updated progress values keyed by achievement id.
        let progress: [String: Double]
    }

    /// Evaluate all definitions against `context`, unlocking any that cross
    /// their threshold on the provided `existing` achievements.
    /// - Parameters:
    ///   - context: The user's current state snapshot.
    ///   - existing: Currently persisted achievements (by id).
    ///   - date: Timestamp to stamp on newly unlocked badges.
    @discardableResult
    static func evaluate(
        context: AchievementContext,
        existing: [String: Achievement],
        at date: Date
    ) -> EvaluationResult {
        var newlyUnlocked: [AchievementCatalog.Definition] = []
        var progressMap: [String: Double] = [:]

        for definition in AchievementCatalog.all {
            let progress = clamp01(definition.evaluate(context))
            progressMap[definition.id] = progress

            guard let achievement = existing[definition.id] else { continue }

            achievement.progress = progress
            if progress >= 1.0 && !achievement.isUnlocked {
                achievement.unlock(at: date)
                newlyUnlocked.append(definition)
            }
        }

        return EvaluationResult(newlyUnlocked: newlyUnlocked, progress: progressMap)
    }

    /// Build a fresh set of achievement models for a new user from the catalog.
    static func seed() -> [Achievement] {
        AchievementCatalog.all.map { $0.makeAchievement() }
    }

    /// Convenience for assembling a context from raw inputs.
    static func makeContext(
        scans: [ScanHistory],
        currentStreak: Int,
        completedRoutines: Int
    ) -> AchievementContext {
        let overallSeries = ProgressTracker.series(from: scans, metric: .overall)
        return AchievementContext(
            scanCount: scans.count,
            currentStreak: currentStreak,
            completedRoutines: completedRoutines,
            overallNetChange: ProgressTracker.netChange(overallSeries),
            bestOverall: overallSeries.map(\.value).max() ?? 0
        )
    }

    private static func clamp01(_ value: Double) -> Double {
        max(0, min(1, value))
    }
}
