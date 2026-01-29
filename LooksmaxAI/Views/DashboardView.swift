import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanHistory.scannedAt, order: .reverse) private var scans: [ScanHistory]
    @Query private var users: [UserStats]

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        if let latestScan = scans.first {
                            // Latest score hero
                            latestScoreSection(scan: latestScan)

                            // Quick stats
                            quickStatsSection(scan: latestScan)

                            // Progress chart
                            if scans.count > 1 {
                                progressSection
                            }

                            // Recent scans
                            recentScansSection
                        } else {
                            // Empty state
                            emptyStateSection
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .navigationTitle("The Lab")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Latest Score Section

    private func latestScoreSection(scan: ScanHistory) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("Current Score")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    Text(String(format: "%.1f", scan.overallPSLScore))
                        .font(DesignSystem.Typography.display(56))
                        .foregroundStyle(DesignSystem.Colors.gradientScore)

                    Text(scan.scoreCategory.rawValue)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(scan.overallPSLScore.scoreColor)
                }

                Spacer()

                // Mini radar chart
                RadarChartView(
                    data: [
                        scan.eyeAreaScore,
                        scan.boneStructureScore,
                        scan.symmetryScore,
                        scan.softmaxBodyScore
                    ],
                    labels: ["", "", "", ""]
                )
                .frame(width: 100, height: 100)
            }

            // Potential bar
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("Potential Max")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(String(format: "%.1f", scan.potentialMaxScore))
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.success)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(DesignSystem.Colors.surfaceTertiary)
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(DesignSystem.Colors.gradientCyan)
                            .frame(width: geometry.size.width * (scan.overallPSLScore / 10), height: 8)
                            .cornerRadius(4)

                        // Potential marker
                        Circle()
                            .fill(DesignSystem.Colors.success)
                            .frame(width: 12, height: 12)
                            .offset(x: geometry.size.width * (scan.potentialMaxScore / 10) - 6)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .glassCard()
    }

    // MARK: - Quick Stats Section

    private func quickStatsSection(scan: ScanHistory) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: DesignSystem.Spacing.md) {
            QuickStatCard(
                title: "Eye Area",
                value: String(format: "%.1f", scan.eyeAreaScore),
                icon: "eye",
                color: DesignSystem.Colors.accentCyan
            )

            QuickStatCard(
                title: "Bone Structure",
                value: String(format: "%.1f", scan.boneStructureScore),
                icon: "face.smiling",
                color: DesignSystem.Colors.accentBlue
            )

            QuickStatCard(
                title: "Symmetry",
                value: String(format: "%.1f", scan.symmetryScore),
                icon: "arrow.left.and.right",
                color: DesignSystem.Colors.accentPurple
            )

            QuickStatCard(
                title: "Body & Skin",
                value: String(format: "%.1f", scan.softmaxBodyScore),
                icon: "figure.stand",
                color: DesignSystem.Colors.accentPink
            )
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Progress")
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.textPrimary)

            // Simple line chart showing score history
            GeometryReader { geometry in
                let recentScans = Array(scans.prefix(7).reversed())
                let maxScore = 10.0
                let minScore = 0.0
                let stepX = geometry.size.width / CGFloat(max(recentScans.count - 1, 1))

                ZStack {
                    // Grid lines
                    ForEach([2.5, 5.0, 7.5], id: \.self) { level in
                        let y = geometry.size.height * (1 - (level - minScore) / (maxScore - minScore))
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        .stroke(DesignSystem.Colors.surfaceTertiary, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }

                    // Line path
                    Path { path in
                        for (index, scan) in recentScans.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = geometry.size.height * (1 - (scan.overallPSLScore - minScore) / (maxScore - minScore))

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        DesignSystem.Colors.accentCyan,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                    // Data points
                    ForEach(recentScans.indices, id: \.self) { index in
                        let scan = recentScans[index]
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height * (1 - (scan.overallPSLScore - minScore) / (maxScore - minScore))

                        Circle()
                            .fill(DesignSystem.Colors.accentCyan)
                            .frame(width: 10, height: 10)
                            .position(x: x, y: y)
                    }
                }
            }
            .frame(height: 150)
            .padding(.top, DesignSystem.Spacing.sm)

            // X-axis labels
            HStack {
                Text("7 days ago")
                Spacer()
                Text("Today")
            }
            .font(DesignSystem.Typography.caption())
            .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.lg)
        .glassCard()
    }

    // MARK: - Recent Scans Section

    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Scan History")
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Spacer()

                if scans.count > 3 {
                    NavigationLink {
                        ScanHistoryListView(scans: scans)
                    } label: {
                        Text("See All")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.accentCyan)
                    }
                }
            }

            ForEach(scans.prefix(3)) { scan in
                NavigationLink {
                    ResultsView(scanHistory: scan)
                } label: {
                    ScanHistoryRow(scan: scan)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "faceid")
                .font(.system(size: 80))
                .foregroundStyle(DesignSystem.Colors.gradientCyan)

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No Scans Yet")
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("Complete your first facial analysis to see your scores and personalized recommendations")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            NavigationLink {
                ScannerView()
            } label: {
                Text("Start Your First Scan")
                    .frame(maxWidth: .infinity)
            }
            .primaryButton()

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)

                Spacer()

                Text(value)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(Double(value)?.scoreColor ?? DesignSystem.Colors.textPrimary)
            }

            Text(title)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .glassCard()
    }
}

// MARK: - Scan History Row

struct ScanHistoryRow: View {
    let scan: ScanHistory

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Score badge
            ZStack {
                Circle()
                    .fill(scan.overallPSLScore.scoreColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Text(String(format: "%.1f", scan.overallPSLScore))
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(scan.overallPSLScore.scoreColor)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(scan.scoreCategory.rawValue)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text(scan.formattedDate)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .glassCard()
    }
}

// MARK: - Scan History List View

struct ScanHistoryListView: View {
    let scans: [ScanHistory]

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(scans) { scan in
                        NavigationLink {
                            ResultsView(scanHistory: scan)
                        } label: {
                            ScanHistoryRow(scan: scan)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .navigationTitle("Scan History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [UserStats.self, ScanHistory.self], inMemory: true)
}
