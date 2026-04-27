import Foundation
import SwiftData

/// Records that the user engaged with the app on a given calendar day
/// (completed a routine, logged hydration, or ran a scan). Used to power
/// streaks and consistency stats.
@Model
final class DailyActivity {
    @Attribute(.unique) var id: UUID

    /// Normalized to the start of the day so there is at most one record per date.
    var day: Date

    // What happened that day
    var completedRoutines: Int
    var loggedHydration: Bool
    var ranScan: Bool

    init(
        day: Date,
        completedRoutines: Int = 0,
        loggedHydration: Bool = false,
        ranScan: Bool = false
    ) {
        self.id = UUID()
        self.day = Calendar.current.startOfDay(for: day)
        self.completedRoutines = completedRoutines
        self.loggedHydration = loggedHydration
        self.ranScan = ranScan
    }

    /// A day "counts" toward a streak if the user did anything meaningful.
    var isActive: Bool {
        completedRoutines > 0 || loggedHydration || ranScan
    }
}
