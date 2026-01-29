import SwiftUI
import AVKit

struct RoutineDetailView: View {
    let recommendation: Recommendation

    @State private var isCompleted = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    headerSection

                    // Video/Image section
                    if recommendation.videoURL != nil || recommendation.imageAsset != nil {
                        mediaSection
                    }

                    // Instructions
                    instructionsSection

                    // Tips
                    if !recommendation.tips.isEmpty {
                        tipsSection
                    }

                    // Difficulty & Timeline
                    metaInfoSection

                    // Mark as complete button
                    completeButton
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle(recommendation.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isCompleted = recommendation.isCompleted
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Category & Priority badges
            HStack(spacing: DesignSystem.Spacing.sm) {
                Label(recommendation.category.rawValue, systemImage: recommendation.category.icon)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(Color(hex: recommendation.category.color))
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(Color(hex: recommendation.category.color).opacity(0.15))
                    .cornerRadius(DesignSystem.CornerRadius.full)

                Text(recommendation.priority.rawValue)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(priorityColor)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(priorityColor.opacity(0.15))
                    .cornerRadius(DesignSystem.CornerRadius.full)

                Spacer()
            }

            // Description
            Text(recommendation.descriptionText)
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Expected improvement
            HStack {
                Image(systemName: "arrow.up.right")
                    .foregroundColor(DesignSystem.Colors.success)

                Text("Expected improvement: +\(String(format: "%.1f", recommendation.expectedImprovement)) to \(recommendation.targetMetric)")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.success)

                Spacer()
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.success.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
        .padding(DesignSystem.Spacing.lg)
        .glassCard()
    }

    // MARK: - Media Section

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Demonstration")
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.textPrimary)

            if let videoURLString = recommendation.videoURL,
               let videoURL = URL(string: videoURLString) {
                // Video player
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 200)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            } else if let imageAsset = recommendation.imageAsset {
                // Image
                Image(imageAsset)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            } else {
                // Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(height: 200)

                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.textTertiary)

                        Text("Video coming soon")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .glassCard()
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Instructions")
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.textPrimary)

            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(recommendation.instructions.indices, id: \.self) { index in
                    InstructionStep(
                        number: index + 1,
                        text: recommendation.instructions[index]
                    )
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .glassCard()
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(DesignSystem.Colors.warning)

                Text("Pro Tips")
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                ForEach(recommendation.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.accentCyan)
                            .font(.system(size: 14))
                            .padding(.top, 2)

                        Text(tip)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.warning.opacity(0.1))
        .glassCard()
    }

    // MARK: - Meta Info Section

    private var metaInfoSection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Difficulty
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Difficulty")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textTertiary)

                Text(recommendation.difficulty.rawValue)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(difficultyColor)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .glassCard()

            // Timeframe
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Timeframe")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textTertiary)

                Text(recommendation.difficulty.estimatedTimeframe)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .glassCard()
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isCompleted.toggle()
                recommendation.isCompleted = isCompleted
                if isCompleted {
                    recommendation.completedAt = Date()
                } else {
                    recommendation.completedAt = nil
                }
            }
        } label: {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                Text(isCompleted ? "Completed" : "Mark as Complete")
            }
            .frame(maxWidth: .infinity)
        }
        .primaryButton(isEnabled: !isCompleted)
        .opacity(isCompleted ? 0.7 : 1)
    }

    // MARK: - Helper Colors

    private var priorityColor: Color {
        switch recommendation.priority {
        case .critical: return DesignSystem.Colors.error
        case .high: return DesignSystem.Colors.warning
        case .medium: return DesignSystem.Colors.accentCyan
        case .low: return DesignSystem.Colors.textSecondary
        }
    }

    private var difficultyColor: Color {
        switch recommendation.difficulty {
        case .easy: return DesignSystem.Colors.success
        case .moderate: return DesignSystem.Colors.accentCyan
        case .challenging: return DesignSystem.Colors.warning
        case .advanced: return DesignSystem.Colors.error
        }
    }
}

// MARK: - Instruction Step

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Text("\(number)")
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.background)
                .frame(width: 24, height: 24)
                .background(DesignSystem.Colors.accentCyan)
                .cornerRadius(DesignSystem.CornerRadius.small)

            Text(text)
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surfaceSecondary)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

#Preview {
    NavigationStack {
        RoutineDetailView(
            recommendation: Recommendation(
                title: "Mewing Technique",
                descriptionText: "Proper tongue posture to enhance jawline definition",
                category: .jawline,
                priority: .critical,
                difficulty: .moderate,
                targetMetric: "gonialAngle",
                expectedImprovement: 0.5,
                instructions: [
                    "Rest entire tongue on roof of mouth",
                    "Teeth should be lightly touching",
                    "Lips closed, breathe through nose",
                    "Maintain posture 24/7 for best results"
                ],
                tips: [
                    "Results take 6-24 months",
                    "Younger individuals see faster changes"
                ]
            )
        )
    }
}
