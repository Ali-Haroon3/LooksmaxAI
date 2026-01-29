import SwiftUI
import SwiftData

struct ResultsView: View {
    let scanHistory: ScanHistory

    @State private var selectedTab = 0
    @State private var animateScore = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Score Hero Section
                    scoreHeroSection

                    // Tab Selector
                    tabSelector

                    // Content based on tab
                    switch selectedTab {
                    case 0:
                        breakdownSection
                    case 1:
                        radarChartSection
                    case 2:
                        recommendationsSection
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Analysis Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                animateScore = true
            }
        }
    }

    // MARK: - Score Hero Section

    private var scoreHeroSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Main score display
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                scanHistory.overallPSLScore.scoreColor.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                // Score ring
                Circle()
                    .stroke(DesignSystem.Colors.surfaceTertiary, lineWidth: 12)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: animateScore ? scanHistory.overallPSLScore / 10 : 0)
                    .stroke(
                        LinearGradient(
                            colors: [
                                scanHistory.overallPSLScore.scoreColor,
                                scanHistory.overallPSLScore.scoreColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                // Score text
                VStack(spacing: DesignSystem.Spacing.xxs) {
                    Text(String(format: "%.1f", scanHistory.overallPSLScore))
                        .font(DesignSystem.Typography.display(48))
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text("PSL Score")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(.top, DesignSystem.Spacing.lg)

            // Category badge
            Text(scanHistory.scoreCategory.rawValue)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(scanHistory.overallPSLScore.scoreColor.opacity(0.2))
                .cornerRadius(DesignSystem.CornerRadius.full)

            // Potential max
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(DesignSystem.Colors.success)

                Text("Potential: \(String(format: "%.1f", scanHistory.potentialMaxScore))")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Text("(+\(String(format: "%.1f", scanHistory.improvementPotential)))")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.success)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .glassCard()
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            ForEach(["Breakdown", "Radar", "Routines"].indices, id: \.self) { index in
                Button {
                    withAnimation { selectedTab = index }
                } label: {
                    Text(["Breakdown", "Radar", "Routines"][index])
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(selectedTab == index ?
                                         DesignSystem.Colors.background :
                                         DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            selectedTab == index ?
                            DesignSystem.Colors.accentCyan :
                            Color.clear
                        )
                        .cornerRadius(DesignSystem.CornerRadius.full)
                }
            }
        }
        .padding(DesignSystem.Spacing.xxs)
        .background(DesignSystem.Colors.surfaceSecondary)
        .cornerRadius(DesignSystem.CornerRadius.full)
    }

    // MARK: - Breakdown Section

    private var breakdownSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Main categories
            ScoreBreakdownCard(
                title: "Eye Area",
                score: scanHistory.eyeAreaScore,
                weight: "30%",
                icon: "eye",
                details: [
                    ("Canthal Tilt", scanHistory.canthalTiltScore),
                    ("IPD", scanHistory.ipdScore),
                    ("Brow Ridge", scanHistory.browRidgeScore)
                ]
            )

            ScoreBreakdownCard(
                title: "Bone Structure",
                score: scanHistory.boneStructureScore,
                weight: "30%",
                icon: "face.smiling",
                details: [
                    ("FWHR", scanHistory.fwhrScore),
                    ("Gonial Angle", scanHistory.gonialAngleScore),
                    ("Cheekbones", scanHistory.cheekboneScore)
                ]
            )

            ScoreBreakdownCard(
                title: "Symmetry",
                score: scanHistory.symmetryScore,
                weight: "20%",
                icon: "arrow.left.and.right",
                details: []
            )

            ScoreBreakdownCard(
                title: "Body & Skin",
                score: scanHistory.softmaxBodyScore,
                weight: "20%",
                icon: "figure.stand",
                details: [
                    ("BMI", scanHistory.bmiScore),
                    ("V-Taper", scanHistory.waistToShoulderScore),
                    ("Skin", scanHistory.skinTextureScore)
                ]
            )
        }
    }

    // MARK: - Radar Chart Section

    private var radarChartSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            RadarChartView(
                data: [
                    scanHistory.eyeAreaScore,
                    scanHistory.boneStructureScore,
                    scanHistory.symmetryScore,
                    scanHistory.softmaxBodyScore
                ],
                labels: ["Eyes", "Bone", "Symmetry", "Body"]
            )
            .frame(height: 300)
            .padding(DesignSystem.Spacing.lg)
            .glassCard()

            // Score distribution
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Score Distribution")
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                HStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(0..<10, id: \.self) { i in
                        let score = Double(i + 1)
                        Rectangle()
                            .fill(score <= scanHistory.overallPSLScore ?
                                  scanHistory.overallPSLScore.scoreColor :
                                  DesignSystem.Colors.surfaceTertiary)
                            .frame(height: 40)
                            .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                }

                HStack {
                    Text("1")
                    Spacer()
                    Text("10")
                }
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.lg)
            .glassCard()
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if scanHistory.recommendations.isEmpty {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(DesignSystem.Colors.success)

                    Text("No major improvements needed!")
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text("Your scores are above average across all metrics.")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(DesignSystem.Spacing.xxl)
                .glassCard()
            } else {
                ForEach(scanHistory.recommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
}

// MARK: - Score Breakdown Card

struct ScoreBreakdownCard: View {
    let title: String
    let score: Double
    let weight: String
    let icon: String
    let details: [(String, Double)]

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(DesignSystem.Colors.accentCyan)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text(title)
                            .font(DesignSystem.Typography.title())
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Text(weight)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }

                    Spacer()

                    Text(String(format: "%.1f", score))
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(score.scoreColor)

                    if !details.isEmpty {
                        Image(systemName: "chevron.down")
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .buttonStyle(.plain)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignSystem.Colors.surfaceTertiary)
                        .frame(height: 4)

                    Rectangle()
                        .fill(score.scoreColor)
                        .frame(width: geometry.size.width * (score / 10), height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, DesignSystem.Spacing.md)

            // Expanded details
            if isExpanded && !details.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(details, id: \.0) { detail in
                        HStack {
                            Text(detail.0)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.textSecondary)

                            Spacer()

                            Text(String(format: "%.1f", detail.1))
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(detail.1.scoreColor)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard()
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: Recommendation

    var body: some View {
        NavigationLink {
            RoutineDetailView(recommendation: recommendation)
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Category icon
                Image(systemName: recommendation.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: categoryColor))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: categoryColor).opacity(0.2))
                    .cornerRadius(DesignSystem.CornerRadius.medium)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(recommendation.title)
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text(recommendation.category.rawValue)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                // Priority badge
                Text(recommendation.priority.rawValue)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(priorityColor)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(priorityColor.opacity(0.2))
                    .cornerRadius(DesignSystem.CornerRadius.full)

                Image(systemName: "chevron.right")
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var categoryColor: String {
        recommendation.category.color
    }

    private var priorityColor: Color {
        switch recommendation.priority {
        case .critical: return DesignSystem.Colors.error
        case .high: return DesignSystem.Colors.warning
        case .medium: return DesignSystem.Colors.accentCyan
        case .low: return DesignSystem.Colors.textSecondary
        }
    }
}

// MARK: - Radar Chart View

struct RadarChartView: View {
    let data: [Double]
    let labels: [String]
    let maxValue: Double = 10

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 40

            ZStack {
                // Grid lines
                ForEach(1...5, id: \.self) { level in
                    let levelRadius = radius * Double(level) / 5
                    Path { path in
                        for i in 0..<data.count {
                            let angle = angleFor(index: i)
                            let point = pointFor(center: center, radius: levelRadius, angle: angle)
                            if i == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                        path.closeSubpath()
                    }
                    .stroke(DesignSystem.Colors.surfaceTertiary, lineWidth: 1)
                }

                // Axis lines
                ForEach(0..<data.count, id: \.self) { i in
                    let angle = angleFor(index: i)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: pointFor(center: center, radius: radius, angle: angle))
                    }
                    .stroke(DesignSystem.Colors.surfaceTertiary, lineWidth: 1)
                }

                // Data polygon
                Path { path in
                    for i in 0..<data.count {
                        let angle = angleFor(index: i)
                        let value = data[i] / maxValue
                        let point = pointFor(center: center, radius: radius * value, angle: angle)
                        if i == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .fill(DesignSystem.Colors.accentCyan.opacity(0.3))
                .overlay(
                    Path { path in
                        for i in 0..<data.count {
                            let angle = angleFor(index: i)
                            let value = data[i] / maxValue
                            let point = pointFor(center: center, radius: radius * value, angle: angle)
                            if i == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                        path.closeSubpath()
                    }
                    .stroke(DesignSystem.Colors.accentCyan, lineWidth: 2)
                )

                // Data points
                ForEach(0..<data.count, id: \.self) { i in
                    let angle = angleFor(index: i)
                    let value = data[i] / maxValue
                    let point = pointFor(center: center, radius: radius * value, angle: angle)

                    Circle()
                        .fill(DesignSystem.Colors.accentCyan)
                        .frame(width: 8, height: 8)
                        .position(point)
                }

                // Labels
                ForEach(0..<labels.count, id: \.self) { i in
                    let angle = angleFor(index: i)
                    let labelRadius = radius + 25
                    let point = pointFor(center: center, radius: labelRadius, angle: angle)

                    Text(labels[i])
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .position(point)
                }
            }
        }
    }

    private func angleFor(index: Int) -> Double {
        let slice = 2 * .pi / Double(data.count)
        return slice * Double(index) - .pi / 2
    }

    private func pointFor(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

#Preview {
    NavigationStack {
        ResultsView(scanHistory: ScanHistory())
    }
}
