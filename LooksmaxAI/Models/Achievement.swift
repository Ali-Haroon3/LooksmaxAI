import Foundation
import SwiftData

/// An unlockable badge that rewards consistency and progress milestones.
@Model
final class Achievement {
    @Attribute(.unique) var id: String  // Stable identifier from the catalog

    var title: String
    var detail: String
    var icon: String            // SF Symbol name
    var tier: AchievementTier

    var isUnlocked: Bool
    var unlockedAt: Date?

    /// 0...1 progress toward unlocking (for badges with a threshold).
    var progress: Double

    init(
        id: String,
        title: String,
        detail: String,
        icon: String,
        tier: AchievementTier,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        progress: Double = 0
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.icon = icon
        self.tier = tier
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.progress = progress
    }

    func unlock(at date: Date) {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedAt = date
        progress = 1.0
    }
}

// MARK: - Tier

enum AchievementTier: String, Codable, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"

    var colorHex: String {
        switch self {
        case .bronze: return "CD7F32"
        case .silver: return "C0C0C0"
        case .gold: return "FFD700"
        case .platinum: return "00D4FF"
        }
    }

    var sortOrder: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        case .platinum: return 3
        }
    }
}
