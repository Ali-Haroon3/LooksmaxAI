import Foundation

/// Static definition of every achievement the app can award, plus the rule
/// used to evaluate it. Keeping the catalog in one place makes it easy to add
/// new badges without touching the engine.
enum AchievementCatalog {

    /// How an achievement is evaluated against the user's current state.
    struct Definition: Identifiable {
        let id: String
        let title: String
        let detail: String
        let icon: String
        let tier: AchievementTier
        /// Returns 0...1 progress given the evaluation context.
        let evaluate: (AchievementContext) -> Double

        func makeAchievement() -> Achievement {
            Achievement(id: id, title: title, detail: detail, icon: icon, tier: tier)
        }
    }

    static let all: [Definition] = [
        Definition(
            id: "first_scan",
            title: "First Look",
            detail: "Complete your first face scan.",
            icon: "faceid",
            tier: .bronze,
            evaluate: { $0.scanCount >= 1 ? 1 : 0 }
        ),
        Definition(
            id: "five_scans",
            title: "Data Point",
            detail: "Log five scans to start seeing trends.",
            icon: "chart.dots.scatter",
            tier: .silver,
            evaluate: { min(1, Double($0.scanCount) / 5.0) }
        ),
        Definition(
            id: "streak_7",
            title: "Consistent",
            detail: "Stay active seven days in a row.",
            icon: "flame",
            tier: .silver,
            evaluate: { min(1, Double($0.currentStreak) / 7.0) }
        ),
        Definition(
            id: "streak_30",
            title: "Disciplined",
            detail: "Reach a 30-day streak.",
            icon: "flame.fill",
            tier: .gold,
            evaluate: { min(1, Double($0.currentStreak) / 30.0) }
        ),
        Definition(
            id: "routine_50",
            title: "Grinder",
            detail: "Complete fifty routines.",
            icon: "checkmark.seal",
            tier: .gold,
            evaluate: { min(1, Double($0.completedRoutines) / 50.0) }
        ),
        Definition(
            id: "score_up_one",
            title: "Trending Up",
            detail: "Improve your overall PSL score by a full point.",
            icon: "arrow.up.forward",
            tier: .gold,
            evaluate: { min(1, max(0, $0.overallNetChange) / 1.0) }
        ),
        Definition(
            id: "score_8",
            title: "Chad Tier",
            detail: "Reach an overall PSL score of 8.0.",
            icon: "crown",
            tier: .platinum,
            evaluate: { min(1, $0.bestOverall / 8.0) }
        )
    ]

    static func definition(for id: String) -> Definition? {
        all.first { $0.id == id }
    }
}

/// Snapshot of the user's state used to evaluate achievements.
struct AchievementContext {
    let scanCount: Int
    let currentStreak: Int
    let completedRoutines: Int
    let overallNetChange: Double
    let bestOverall: Double
}
