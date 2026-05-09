# Changelog

All notable changes to LooksmaxAI are documented here.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added

- **Progress tracking** — `ProgressTracker` derives trends, moving averages, and
  linear-regression momentum from scan history; surfaced via `ProgressChartView`
  (Swift Charts) and `MetricTrendRow`.
- **Before/after comparison** — `ScanComparison` diffs the first and latest scans
  per metric; presented in `ComparisonView`.
- **Streaks & consistency** — `DailyActivity` model plus `StreakTracker`
  (current / longest streak, trailing-window consistency).
- **Achievements** — tiered badge system (`Achievement`, `AchievementCatalog`,
  `AchievementEngine`) rewarding scan counts, streaks, and score gains.
- **Hydration tracking** — `HydrationLog` model and `HydrationView` with a
  circular progress ring and quick-add servings.
- **Golden-ratio analysis** — `GoldenRatio` computes φ-harmony across facial
  proportions; `PhiMaskOverlay` draws a golden-grid overlay.
- **Sharing** — `ReportGenerator` produces plain-text/structured summaries and
  `ShareableCardView` renders a screenshot-ready result card.
- **Daily insights** — `InsightsLibrary` and `TipOfTheDayView` surface one
  curated tip per day.
- **Haptics** — centralized `HapticManager` for consistent tactile feedback.
- **Tests** — unit tests for `FaceMath`, `ScoringEngine`, and `ProgressTracker`,
  plus an SPM test target.

## [1.0.0]

### Added

- Initial release: AI face scanner, PSL scoring engine, The Lab dashboard,
  routine library, and profile management.
