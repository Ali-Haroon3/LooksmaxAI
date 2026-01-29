import Foundation

/// RoutineLibrary: JSON-backed database of improvement routines
/// Maps metric scores to appropriate recommendations
struct RoutineLibrary {

    // MARK: - Get Recommendations

    /// Generate recommendations based on scan results
    static func getRecommendations(
        for result: ScanResult,
        userStats: UserStats
    ) -> [RecommendationData] {
        var recommendations: [RecommendationData] = []

        // Eye Area recommendations
        recommendations.append(contentsOf: getEyeAreaRecommendations(from: result.eyeArea))

        // Bone Structure recommendations
        recommendations.append(contentsOf: getBoneStructureRecommendations(from: result.boneStructure))

        // Body/Softmax recommendations
        recommendations.append(contentsOf: getBodyRecommendations(from: result.softmaxBody, userStats: userStats))

        // General recommendations
        recommendations.append(contentsOf: getGeneralRecommendations())

        // Sort by priority and deduplicate
        return recommendations
            .sorted { $0.priority < $1.priority }
    }

    // MARK: - Eye Area Recommendations

    private static func getEyeAreaRecommendations(from scores: EyeAreaScore) -> [RecommendationData] {
        var recs: [RecommendationData] = []

        // Negative canthal tilt
        if scores.canthalTiltScore < 6 {
            recs.append(eyebrowGroomingRoutine)
            recs.append(sleepOptimizationRoutine)
            recs.append(underEyeCareRoutine)
        }

        // Low brow ridge prominence
        if scores.browRidgeScore < 6 {
            recs.append(browEnhancementRoutine)
        }

        return recs
    }

    // MARK: - Bone Structure Recommendations

    private static func getBoneStructureRecommendations(from scores: BoneStructureScore) -> [RecommendationData] {
        var recs: [RecommendationData] = []

        // Weak jawline (high gonial angle or low FWHR)
        if scores.gonialAngleScore < 7 || scores.fwhrScore < 7 {
            recs.append(mewingRoutine)
            recs.append(chewingRoutine)
            recs.append(jawExerciseRoutine)
        }

        // Low cheekbone prominence
        if scores.cheekboneScore < 7 {
            recs.append(facialMassageRoutine)
        }

        return recs
    }

    // MARK: - Body Recommendations

    private static func getBodyRecommendations(
        from scores: SoftmaxScore,
        userStats: UserStats
    ) -> [RecommendationData] {
        var recs: [RecommendationData] = []

        // High BMI - prioritize fat loss
        if scores.bmiScore < 7 {
            if userStats.bmi > 25 {
                recs.append(fatLossRoutine)
            } else if userStats.bmi < 18.5 {
                recs.append(muscleGainRoutine)
            }
        }

        // Poor waist-to-shoulder ratio
        if scores.waistToShoulderScore < 7 {
            recs.append(vTaperRoutine)
        }

        // Skin improvements
        if scores.skinTextureScore < 8 {
            recs.append(skincareRoutine)
            recs.append(hydrationRoutine)
        }

        return recs
    }

    // MARK: - General Recommendations

    private static func getGeneralRecommendations() -> [RecommendationData] {
        return [
            postureRoutine,
            haircareRoutine
        ]
    }

    // MARK: - Routine Definitions

    // Eye Area Routines

    static let eyebrowGroomingRoutine = RecommendationData(
        title: "Eyebrow Grooming",
        description: "Shape eyebrows to create visual lift and enhance eye area appearance",
        category: .grooming,
        priority: .high,
        targetMetric: "canthalTilt",
        expectedImprovement: 0.3,
        instructions: [
            "Avoid over-plucking - maintain natural thickness",
            "Create slight arch at 2/3 point from inner corner",
            "Remove stray hairs below brow only",
            "Trim any overly long hairs with small scissors",
            "Consider professional shaping for first session"
        ],
        tips: [
            "Hunter eyes illusion can be created through proper grooming",
            "Avoid rounded brow shapes - slight angles are more aesthetic",
            "Men should maintain fullness while cleaning up edges"
        ]
    )

    static let sleepOptimizationRoutine = RecommendationData(
        title: "Sleep Optimization",
        description: "Quality sleep reduces eye puffiness and improves overall eye area appearance",
        category: .sleep,
        priority: .high,
        targetMetric: "canthalTilt",
        expectedImprovement: 0.2,
        instructions: [
            "Aim for 7-9 hours of quality sleep per night",
            "Sleep on your back to prevent eye compression",
            "Use silk pillowcase to reduce friction and skin creasing",
            "Keep room temperature cool (65-68°F / 18-20°C)",
            "Avoid screens 1 hour before bed (blue light)",
            "Elevate head slightly to reduce fluid accumulation"
        ],
        tips: [
            "Consistent sleep schedule is more important than duration",
            "Quality > Quantity - optimize sleep environment",
            "Consider sleep tracking to identify patterns"
        ]
    )

    static let underEyeCareRoutine = RecommendationData(
        title: "Under-Eye Care",
        description: "Reduce dark circles and puffiness for improved eye area",
        category: .skincare,
        priority: .medium,
        targetMetric: "canthalTilt",
        expectedImprovement: 0.15,
        instructions: [
            "Apply cold compress for 5-10 minutes in the morning",
            "Use eye cream with caffeine and vitamin K",
            "Stay hydrated - dehydration worsens dark circles",
            "Reduce sodium intake to minimize water retention",
            "Apply sunscreen to prevent hyperpigmentation"
        ],
        tips: [
            "Genetics play a role - manage expectations",
            "Consistency is key - daily routine matters",
            "Consider allergy testing if circles persist"
        ]
    )

    static let browEnhancementRoutine = RecommendationData(
        title: "Brow Ridge Enhancement",
        description: "Visual techniques to enhance brow ridge appearance",
        category: .grooming,
        priority: .medium,
        targetMetric: "browRidge",
        expectedImprovement: 0.2,
        instructions: [
            "Maintain thick, well-shaped eyebrows",
            "Use matte bronzer to create shadow under brow bone",
            "Avoid over-plucking which reduces visual projection",
            "Consider brow lamination for lifted appearance"
        ],
        tips: [
            "Natural enhancement through grooming is most effective",
            "Lighting can dramatically affect perceived projection",
            "Work with your natural brow shape"
        ]
    )

    // Jawline Routines

    static let mewingRoutine = RecommendationData(
        title: "Mewing Technique",
        description: "Proper tongue posture to enhance jawline definition over time",
        category: .jawline,
        priority: .critical,
        targetMetric: "gonialAngle",
        expectedImprovement: 0.5,
        instructions: [
            "Rest entire tongue flat against roof of mouth",
            "The back third of tongue should press upward",
            "Teeth should be lightly touching or close together",
            "Lips closed at all times, breathe through nose",
            "Maintain this posture 24/7 for best results",
            "Chin should remain level, not tucked or jutting"
        ],
        tips: [
            "Results typically take 6-24 months to become visible",
            "Younger individuals (under 25) see faster changes",
            "Focus on making it habitual - conscious effort initially",
            "Some claim it helps with sleep apnea and breathing"
        ]
    )

    static let chewingRoutine = RecommendationData(
        title: "Chewing Exercises",
        description: "Strengthen masseter muscles for improved jaw definition",
        category: .jawline,
        priority: .high,
        targetMetric: "gonialAngle",
        expectedImprovement: 0.4,
        instructions: [
            "Use mastic gum or hard gum (Falim is popular)",
            "Chew for 20-30 minutes daily",
            "Alternate sides evenly to prevent asymmetry",
            "Start with 10 minutes and gradually increase",
            "Take rest days - 3-4 days per week is sufficient"
        ],
        tips: [
            "Don't overdo it - TMJ issues can occur",
            "If jaw pain occurs, reduce frequency immediately",
            "Focus on even, controlled chewing motion",
            "Results visible in 2-3 months with consistency"
        ]
    )

    static let jawExerciseRoutine = RecommendationData(
        title: "Jaw Resistance Training",
        description: "Targeted exercises for masseter hypertrophy",
        category: .jawline,
        priority: .medium,
        targetMetric: "gonialAngle",
        expectedImprovement: 0.3,
        instructions: [
            "Jaw clenches: Hold for 5 seconds, release, 10 reps",
            "Chin lifts: Tilt head back, push jaw forward, hold 10 sec",
            "Neck curls: Lie down, lift head, tuck chin, 15 reps",
            "Perform exercises 3-4 times per week"
        ],
        tips: [
            "Form is more important than intensity",
            "Progressive overload - gradually increase hold times",
            "Combine with proper nutrition for muscle growth"
        ]
    )

    static let facialMassageRoutine = RecommendationData(
        title: "Facial Massage & Gua Sha",
        description: "Improve facial circulation and reduce puffiness for enhanced bone definition",
        category: .skincare,
        priority: .low,
        targetMetric: "cheekbones",
        expectedImprovement: 0.15,
        instructions: [
            "Use jade roller or gua sha tool with facial oil",
            "Stroke upward and outward along cheekbones",
            "Apply gentle pressure along jawline",
            "Massage for 5-10 minutes daily",
            "Focus on lymphatic drainage areas (under jaw, behind ears)"
        ],
        tips: [
            "Effects are temporary but cumulative with consistency",
            "Best done in morning to reduce overnight puffiness",
            "Keep tools clean to prevent breakouts"
        ]
    )

    // Body Routines

    static let fatLossRoutine = RecommendationData(
        title: "Fat Loss Protocol",
        description: "Reduce body fat to reveal facial bone structure",
        category: .fitness,
        priority: .critical,
        targetMetric: "bmi",
        expectedImprovement: 0.8,
        instructions: [
            "Calculate TDEE and create 300-500 calorie deficit",
            "Prioritize protein intake (1g per lb bodyweight)",
            "Resistance training 3-4x per week to preserve muscle",
            "Include 2-3 cardio sessions (20-30 min) weekly",
            "Track progress weekly - aim for 0.5-1 lb loss per week",
            "Stay hydrated - minimum 8 glasses water daily"
        ],
        tips: [
            "Lower body fat dramatically improves facial aesthetics",
            "Don't cut too aggressively - muscle loss is counterproductive",
            "Face gains typically visible at 15% body fat and below (men)",
            "Take progress photos - scale weight fluctuates"
        ]
    )

    static let muscleGainRoutine = RecommendationData(
        title: "Lean Muscle Building",
        description: "Build muscle mass for improved body composition",
        category: .fitness,
        priority: .high,
        targetMetric: "bmi",
        expectedImprovement: 0.5,
        instructions: [
            "Slight caloric surplus (200-300 above maintenance)",
            "High protein diet (1-1.2g per lb bodyweight)",
            "Progressive overload in compound lifts",
            "Focus on bench, squat, deadlift, rows, overhead press",
            "Train each muscle group 2x per week",
            "Prioritize sleep for recovery (7-9 hours)"
        ],
        tips: [
            "Lean bulk prevents excessive fat gain",
            "Track lifts to ensure progressive overload",
            "Patience - muscle building takes time"
        ]
    )

    static let vTaperRoutine = RecommendationData(
        title: "V-Taper Development",
        description: "Build shoulder width and reduce waist for ideal masculine proportions",
        category: .fitness,
        priority: .high,
        targetMetric: "waistToShoulder",
        expectedImprovement: 0.5,
        instructions: [
            "Prioritize lateral deltoid development (lateral raises)",
            "Include overhead pressing movements 2x weekly",
            "Build lat width with pull-ups and rows",
            "Core work focused on transverse abdominis (vacuum exercises)",
            "Avoid excessive oblique work (can widen waist)",
            "Sample split: Push/Pull/Legs with shoulder emphasis"
        ],
        tips: [
            "Lateral raises are key - 3-4 sets, 12-15 reps, multiple times per week",
            "Mind-muscle connection crucial for deltoid development",
            "Waist reduction comes from fat loss + core tightening"
        ]
    )

    // Skincare Routines

    static let skincareRoutine = RecommendationData(
        title: "Core Skincare Protocol",
        description: "Comprehensive routine for clear, healthy skin",
        category: .skincare,
        priority: .medium,
        targetMetric: "skinTexture",
        expectedImprovement: 0.4,
        instructions: [
            "AM: Gentle cleanser → Vitamin C serum → Moisturizer → SPF 30+",
            "PM: Oil cleanser (if wearing SPF) → Gentle cleanser → Retinoid → Moisturizer",
            "Start retinoids slowly (2-3x per week) to avoid irritation",
            "Patch test new products before full application",
            "Give products 6-8 weeks before judging effectiveness"
        ],
        tips: [
            "Tretinoin is the gold standard for anti-aging and texture",
            "SPF is non-negotiable - prevents aging and hyperpigmentation",
            "Less is more - simple routine beats 10-step routines",
            "Consult dermatologist for prescription retinoids"
        ]
    )

    static let hydrationRoutine = RecommendationData(
        title: "Hydration Optimization",
        description: "Proper hydration for skin health and facial fullness",
        category: .nutrition,
        priority: .low,
        targetMetric: "skinTexture",
        expectedImprovement: 0.2,
        instructions: [
            "Drink minimum 8 glasses (64oz) of water daily",
            "Increase intake during exercise or hot weather",
            "Limit alcohol and caffeine (diuretic effects)",
            "Eat water-rich foods (cucumber, watermelon, etc.)",
            "Use humidifier in dry environments"
        ],
        tips: [
            "Urine color is a good hydration indicator (pale yellow is ideal)",
            "Electrolytes help with absorption (add pinch of salt)",
            "Dehydration makes face look gaunt and skin dull"
        ]
    )

    // General Routines

    static let postureRoutine = RecommendationData(
        title: "Posture Correction",
        description: "Improve posture for better jawline presentation and overall appearance",
        category: .posture,
        priority: .medium,
        targetMetric: "general",
        expectedImprovement: 0.3,
        instructions: [
            "Chin tucks: Pull chin back (make double chin), hold 5 sec, 10 reps",
            "Wall angels: Stand against wall, raise arms overhead, 10 reps",
            "Doorway chest stretch: 30 seconds each side, 3x daily",
            "Strengthen upper back with rows and face pulls",
            "Set hourly reminders to check posture throughout day"
        ],
        tips: [
            "Forward head posture makes jaw appear recessed",
            "Good posture instantly improves appearance",
            "Ergonomic workspace setup is crucial",
            "Results from exercises take 4-8 weeks"
        ]
    )

    static let haircareRoutine = RecommendationData(
        title: "Hair Optimization",
        description: "Maintain healthy hair to frame and enhance facial features",
        category: .grooming,
        priority: .low,
        targetMetric: "general",
        expectedImprovement: 0.2,
        instructions: [
            "Find a hairstyle that suits your face shape",
            "Get regular trims every 4-6 weeks",
            "Use quality shampoo and conditioner",
            "Consider minoxidil if experiencing hair loss",
            "Avoid excessive heat styling"
        ],
        tips: [
            "Hairstyle can dramatically change face perception",
            "Consult barber/stylist for face shape recommendations",
            "Healthy hair requires proper nutrition"
        ]
    )
}

// MARK: - JSON Export Helper

extension RoutineLibrary {

    /// Export all routines as JSON (for debugging/backup)
    static func exportAsJSON() -> String? {
        let allRoutines = [
            eyebrowGroomingRoutine,
            sleepOptimizationRoutine,
            underEyeCareRoutine,
            browEnhancementRoutine,
            mewingRoutine,
            chewingRoutine,
            jawExerciseRoutine,
            facialMassageRoutine,
            fatLossRoutine,
            muscleGainRoutine,
            vTaperRoutine,
            skincareRoutine,
            hydrationRoutine,
            postureRoutine,
            haircareRoutine
        ]

        struct ExportableRoutine: Encodable {
            let title: String
            let description: String
            let category: String
            let priority: String
            let targetMetric: String
            let expectedImprovement: Double
            let instructions: [String]
            let tips: [String]
        }

        let exportable = allRoutines.map { routine in
            ExportableRoutine(
                title: routine.title,
                description: routine.description,
                category: routine.category.rawValue,
                priority: routine.priority.rawValue,
                targetMetric: routine.targetMetric,
                expectedImprovement: routine.expectedImprovement,
                instructions: routine.instructions,
                tips: routine.tips
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(exportable),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return json
    }
}
