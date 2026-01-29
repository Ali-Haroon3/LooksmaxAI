import Foundation
import SwiftData

/// User profile containing body measurements and personal stats
@Model
final class UserStats {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Personal Info
    var age: Int
    var gender: Gender

    // Body Measurements (in metric)
    var heightCm: Double
    var weightKg: Double
    var neckCm: Double
    var waistCm: Double
    var shoulderCm: Double

    // Calculated Properties
    var bmi: Double {
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    var waistToShoulderRatio: Double {
        guard shoulderCm > 0 else { return 0 }
        return waistCm / shoulderCm
    }

    var bmiCategory: BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case 18.5..<25: return .normal
        case 25..<30: return .overweight
        default: return .obese
        }
    }

    // Relationship
    @Relationship(deleteRule: .cascade, inverse: \ScanHistory.userStats)
    var scanHistory: [ScanHistory] = []

    init(
        age: Int = 25,
        gender: Gender = .male,
        heightCm: Double = 175,
        weightKg: Double = 75,
        neckCm: Double = 38,
        waistCm: Double = 82,
        shoulderCm: Double = 115
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.age = age
        self.gender = gender
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.neckCm = neckCm
        self.waistCm = waistCm
        self.shoulderCm = shoulderCm
    }
}

// MARK: - Supporting Enums

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

enum BMICategory: String, Codable {
    case underweight = "Underweight"
    case normal = "Normal"
    case overweight = "Overweight"
    case obese = "Obese"

    var color: String {
        switch self {
        case .underweight: return "yellow"
        case .normal: return "green"
        case .overweight: return "orange"
        case .obese: return "red"
        }
    }
}
