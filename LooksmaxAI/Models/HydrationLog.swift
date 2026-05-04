import Foundation
import SwiftData

/// Water intake logged for a single calendar day. Hydration supports skin
/// quality, so it feeds the softmax side of the score indirectly via routines.
@Model
final class HydrationLog {
    @Attribute(.unique) var id: UUID

    /// Normalized to start of day.
    var day: Date

    /// Total intake in millilitres.
    var amountML: Int

    /// Goal snapshot at the time of logging (so history reflects the goal then).
    var goalML: Int

    init(day: Date, amountML: Int = 0, goalML: Int = 2500) {
        self.id = UUID()
        self.day = Calendar.current.startOfDay(for: day)
        self.amountML = amountML
        self.goalML = goalML
    }

    // MARK: - Derived

    /// Progress toward goal, clamped 0...1.
    var progress: Double {
        guard goalML > 0 else { return 0 }
        return min(1, Double(amountML) / Double(goalML))
    }

    var goalMet: Bool { amountML >= goalML }

    var litresLabel: String {
        String(format: "%.1f L", Double(amountML) / 1000.0)
    }

    // MARK: - Mutation

    func add(_ ml: Int) {
        amountML = max(0, amountML + ml)
    }
}

/// Common quick-add serving sizes in millilitres.
enum HydrationServing: Int, CaseIterable, Identifiable {
    case glass = 250
    case bottle = 500
    case largeBottle = 750

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .glass: return "Glass"
        case .bottle: return "Bottle"
        case .largeBottle: return "Large"
        }
    }

    var icon: String {
        switch self {
        case .glass: return "cup.and.saucer"
        case .bottle: return "waterbottle"
        case .largeBottle: return "waterbottle.fill"
        }
    }
}
