import SwiftUI
import SwiftData

/// Daily water intake tracker with a circular progress ring and quick-add
/// serving buttons.
struct HydrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var logs: [HydrationLog]

    @State private var today = Date()

    private let goalML = 2500

    private var todayLog: HydrationLog? {
        logs.first { Calendar.current.isDate($0.day, inSameDayAs: today) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: DesignSystem.Spacing.xl) {
                    ring
                    servingButtons
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.xl)
            }
            .navigationTitle("Hydration")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Ring

    private var ring: some View {
        let progress = todayLog?.progress ?? 0
        let amount = todayLog?.amountML ?? 0

        return ZStack {
            Circle()
                .stroke(DesignSystem.Colors.surfaceTertiary, lineWidth: 18)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    DesignSystem.Colors.gradientCyan,
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            VStack(spacing: 4) {
                Text(String(format: "%.1f L", Double(amount) / 1000.0))
                    .font(DesignSystem.Typography.display(40))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text("of \(String(format: "%.1f L", Double(goalML) / 1000.0))")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(width: 220, height: 220)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }

    // MARK: - Serving Buttons

    private var servingButtons: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(HydrationServing.allCases) { serving in
                Button {
                    add(serving.rawValue)
                } label: {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: serving.icon)
                            .font(.system(size: 24))
                        Text(serving.label)
                            .font(DesignSystem.Typography.caption(12))
                        Text("\(serving.rawValue) mL")
                            .font(DesignSystem.Typography.mono(11))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    .foregroundColor(DesignSystem.Colors.accentCyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .glassCard(cornerRadius: DesignSystem.CornerRadius.medium)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func add(_ ml: Int) {
        let log = todayLog ?? {
            let created = HydrationLog(day: today, goalML: goalML)
            modelContext.insert(created)
            return created
        }()
        let wasBelowGoal = !log.goalMet
        log.add(ml)
        (wasBelowGoal && log.goalMet) ? HapticManager.shared.success() : HapticManager.shared.impact(.light)
    }
}
