import Foundation

/// A curated set of short, evidence-minded tips surfaced one-per-day on the
/// dashboard. Deterministic selection (by day-of-year) so the tip is stable
/// across a single day without needing persistence.
enum InsightsLibrary {

    struct Insight: Identifiable {
        let id: Int
        let category: RecommendationCategory
        let headline: String
        let body: String
    }

    static let all: [Insight] = [
        Insight(
            id: 0,
            category: .sleep,
            headline: "Sleep is the cheapest maxing",
            body: "Deep sleep drives collagen turnover and reduces under-eye puffiness. Aim for a consistent 7–9 hours before chasing anything fancier."
        ),
        Insight(
            id: 1,
            category: .skincare,
            headline: "Sunscreen beats every serum",
            body: "UV exposure is the largest driver of visible skin aging. Daily SPF 30+ protects the gains from the rest of your routine."
        ),
        Insight(
            id: 2,
            category: .fitness,
            headline: "Lower body fat sharpens the face",
            body: "Facial bone structure reveals itself as body fat drops toward 10–15%. Recomposition often does more than any single facial exercise."
        ),
        Insight(
            id: 3,
            category: .jawline,
            headline: "Mewing is posture, not magic",
            body: "Resting the tongue on the palate improves oral posture over months. Treat it as a long-term habit, not an overnight fix."
        ),
        Insight(
            id: 4,
            category: .nutrition,
            headline: "Sodium shows on your face",
            body: "High-sodium meals cause water retention and facial bloat. Watch salt the day before anything that matters."
        ),
        Insight(
            id: 5,
            category: .posture,
            headline: "Stand tall, look taller",
            body: "Forward head posture shortens the neck and softens the jawline. Chin tucks and upper-back work help more than you'd think."
        ),
        Insight(
            id: 6,
            category: .grooming,
            headline: "Brows frame the eyes",
            body: "Clean, well-shaped brows do more for the eye area than most people expect — and cost nothing but a few minutes."
        ),
        Insight(
            id: 7,
            category: .lifestyle,
            headline: "Hydration is a free glow-up",
            body: "Even mild dehydration dulls skin and deepens under-eye shadows. Hit your water goal before reaching for products."
        )
    ]

    /// The insight for a given date, chosen deterministically by day-of-year.
    static func insight(for date: Date, calendar: Calendar = .current) -> Insight {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % all.count
        return all[index]
    }
}
