import Foundation
import SwiftData

/// A personalized improvement recommendation based on scan results
@Model
final class Recommendation {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    // Recommendation Details
    var title: String
    var descriptionText: String
    var category: RecommendationCategory
    var priority: Priority
    var difficulty: Difficulty

    // Targeting
    var targetMetric: String  // Which metric this addresses
    var expectedImprovement: Double  // Expected score improvement

    // Content
    var instructions: [String]
    var tips: [String]
    var videoURL: String?
    var imageAsset: String?

    // Progress Tracking
    var isCompleted: Bool
    var completedAt: Date?

    // Relationship
    var scanHistory: ScanHistory?

    init(
        title: String,
        descriptionText: String,
        category: RecommendationCategory,
        priority: Priority = .medium,
        difficulty: Difficulty = .moderate,
        targetMetric: String,
        expectedImprovement: Double = 0.5,
        instructions: [String] = [],
        tips: [String] = [],
        videoURL: String? = nil,
        imageAsset: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.title = title
        self.descriptionText = descriptionText
        self.category = category
        self.priority = priority
        self.difficulty = difficulty
        self.targetMetric = targetMetric
        self.expectedImprovement = expectedImprovement
        self.instructions = instructions
        self.tips = tips
        self.videoURL = videoURL
        self.imageAsset = imageAsset
        self.isCompleted = false
        self.completedAt = nil
    }
}

// MARK: - Supporting Enums

enum RecommendationCategory: String, Codable, CaseIterable {
    case eyeArea = "Eye Area"
    case jawline = "Jawline"
    case skincare = "Skincare"
    case grooming = "Grooming"
    case fitness = "Fitness"
    case posture = "Posture"
    case sleep = "Sleep & Recovery"
    case nutrition = "Nutrition"
    case lifestyle = "Lifestyle"

    var icon: String {
        switch self {
        case .eyeArea: return "eye"
        case .jawline: return "face.smiling"
        case .skincare: return "drop"
        case .grooming: return "scissors"
        case .fitness: return "figure.walk"
        case .posture: return "figure.stand"
        case .sleep: return "moon.zzz"
        case .nutrition: return "leaf"
        case .lifestyle: return "star"
        }
    }

    var color: String {
        switch self {
        case .eyeArea: return "cyan"
        case .jawline: return "blue"
        case .skincare: return "pink"
        case .grooming: return "orange"
        case .fitness: return "red"
        case .posture: return "purple"
        case .sleep: return "indigo"
        case .nutrition: return "green"
        case .lifestyle: return "yellow"
        }
    }
}

enum Priority: String, Codable, CaseIterable, Comparable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case moderate = "Moderate"
    case challenging = "Challenging"
    case advanced = "Advanced"

    var estimatedTimeframe: String {
        switch self {
        case .easy: return "1-2 weeks"
        case .moderate: return "1-3 months"
        case .challenging: return "3-6 months"
        case .advanced: return "6+ months"
        }
    }
}
