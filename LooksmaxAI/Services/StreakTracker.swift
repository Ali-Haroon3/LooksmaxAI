import Foundation

/// Derives current / longest streaks and consistency stats from a set of
/// `DailyActivity` records. Calendar-aware so timezone day boundaries are
/// respected.
enum StreakTracker {

    private static var calendar: Calendar { Calendar.current }

    // MARK: - Current Streak

    /// The number of consecutive active days ending today (or yesterday, so
    /// the streak doesn't visually "break" before the user acts today).
    static func currentStreak(from activities: [DailyActivity], asOf reference: Date) -> Int {
        let activeDays = normalizedActiveDays(from: activities)
        guard !activeDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: reference)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        // Anchor the streak to today if active, otherwise yesterday.
        var cursor: Date
        if activeDays.contains(today) {
            cursor = today
        } else if activeDays.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var streak = 0
        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    // MARK: - Longest Streak

    /// The longest run of consecutive active days ever recorded.
    static func longestStreak(from activities: [DailyActivity]) -> Int {
        let sorted = normalizedActiveDays(from: activities).sorted()
        guard !sorted.isEmpty else { return 0 }

        var longest = 1
        var running = 1

        for index in 1..<sorted.count {
            let previous = sorted[index - 1]
            let current = sorted[index]
            if let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: current) {
                running += 1
                longest = max(longest, running)
            } else {
                running = 1
            }
        }
        return longest
    }

    // MARK: - Consistency

    /// Fraction of days that were active within the trailing window.
    /// - Returns: A value in 0...1.
    static func consistency(
        from activities: [DailyActivity],
        window days: Int = 30,
        asOf reference: Date
    ) -> Double {
        guard days > 0 else { return 0 }
        let today = calendar.startOfDay(for: reference)
        guard let windowStart = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return 0 }

        let activeInWindow = normalizedActiveDays(from: activities).filter { $0 >= windowStart && $0 <= today }
        return Double(activeInWindow.count) / Double(days)
    }

    // MARK: - Helpers

    private static func normalizedActiveDays(from activities: [DailyActivity]) -> Set<Date> {
        Set(activities.filter(\.isActive).map { calendar.startOfDay(for: $0.day) })
    }
}
