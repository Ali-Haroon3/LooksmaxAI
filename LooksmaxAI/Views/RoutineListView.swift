import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Query(sort: \Recommendation.createdAt, order: .reverse) private var recommendations: [Recommendation]

    @State private var selectedCategory: RecommendationCategory?
    @State private var searchText = ""

    private var filteredRecommendations: [Recommendation] {
        var filtered = recommendations

        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.descriptionText.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    private var groupedByCategory: [RecommendationCategory: [Recommendation]] {
        Dictionary(grouping: filteredRecommendations, by: { $0.category })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                if recommendations.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // Category filter
                            categoryFilter

                            // Routines list
                            if selectedCategory != nil {
                                // Flat list for selected category
                                ForEach(filteredRecommendations) { recommendation in
                                    NavigationLink {
                                        RoutineDetailView(recommendation: recommendation)
                                    } label: {
                                        RoutineCard(recommendation: recommendation)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                // Grouped by category
                                ForEach(RecommendationCategory.allCases, id: \.self) { category in
                                    if let recs = groupedByCategory[category], !recs.isEmpty {
                                        RoutineCategorySection(
                                            category: category,
                                            recommendations: recs
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.bottom, DesignSystem.Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search routines")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // All button
                CategoryFilterButton(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    color: DesignSystem.Colors.accentCyan
                ) {
                    withAnimation { selectedCategory = nil }
                }

                ForEach(RecommendationCategory.allCases, id: \.self) { category in
                    let hasItems = groupedByCategory[category] != nil
                    if hasItems {
                        CategoryFilterButton(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedCategory == category,
                            color: Color(hex: category.color)
                        ) {
                            withAnimation {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No Routines Yet")
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("Complete a facial scan to receive personalized improvement routines")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Category Filter Button

struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(DesignSystem.Typography.caption())
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.background : color)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(isSelected ? color : color.opacity(0.15))
            .cornerRadius(DesignSystem.CornerRadius.full)
        }
    }
}

// MARK: - Routine Category Section

struct RoutineCategorySection: View {
    let category: RecommendationCategory
    let recommendations: [Recommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(Color(hex: category.color))

                Text(category.rawValue)
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Spacer()

                Text("\(recommendations.count)")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(DesignSystem.Colors.surfaceSecondary)
                    .cornerRadius(DesignSystem.CornerRadius.full)
            }

            ForEach(recommendations) { recommendation in
                NavigationLink {
                    RoutineDetailView(recommendation: recommendation)
                } label: {
                    RoutineCard(recommendation: recommendation)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Routine Card

struct RoutineCard: View {
    let recommendation: Recommendation

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            Image(systemName: recommendation.category.icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: recommendation.category.color))
                .frame(width: 44, height: 44)
                .background(Color(hex: recommendation.category.color).opacity(0.15))
                .cornerRadius(DesignSystem.CornerRadius.medium)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(recommendation.title)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                Text(recommendation.descriptionText)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                // Priority indicator
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)

                // Expected improvement
                if recommendation.expectedImprovement > 0 {
                    Text("+\(String(format: "%.1f", recommendation.expectedImprovement))")
                        .font(DesignSystem.Typography.mono(12))
                        .foregroundColor(DesignSystem.Colors.success)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .glassCard()
    }

    private var priorityColor: Color {
        switch recommendation.priority {
        case .critical: return DesignSystem.Colors.error
        case .high: return DesignSystem.Colors.warning
        case .medium: return DesignSystem.Colors.accentCyan
        case .low: return DesignSystem.Colors.textTertiary
        }
    }
}

#Preview {
    RoutineListView()
        .modelContainer(for: Recommendation.self, inMemory: true)
}
