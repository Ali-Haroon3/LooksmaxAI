import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserStats]
    @Query private var scans: [ScanHistory]

    @State private var showEditSheet = false
    @State private var showResetAlert = false

    private var user: UserStats? { users.first }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Profile header
                        profileHeader

                        // Stats overview
                        if let user = user {
                            statsSection(user: user)
                        }

                        // Body metrics
                        if let user = user {
                            bodyMetricsSection(user: user)
                        }

                        // App info
                        appInfoSection

                        // Danger zone
                        dangerZoneSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Text("Edit")
                            .foregroundColor(DesignSystem.Colors.accentCyan)
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let user = user {
                    EditProfileSheet(user: user)
                }
            }
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will delete all your scans, recommendations, and profile data. This action cannot be undone.")
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .frame(width: 100, height: 100)

                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(DesignSystem.Colors.accentCyan)
            }

            if let user = user {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("\(user.age) years old")
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text(user.gender.rawValue)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }

            // Quick stats
            HStack(spacing: DesignSystem.Spacing.xl) {
                ProfileStat(label: "Scans", value: "\(scans.count)")
                ProfileStat(label: "Best Score", value: bestScore)
                ProfileStat(label: "Avg Score", value: avgScore)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .glassCard()
    }

    private var bestScore: String {
        guard let best = scans.max(by: { $0.overallPSLScore < $1.overallPSLScore }) else {
            return "-"
        }
        return String(format: "%.1f", best.overallPSLScore)
    }

    private var avgScore: String {
        guard !scans.isEmpty else { return "-" }
        let avg = scans.reduce(0.0) { $0 + $1.overallPSLScore } / Double(scans.count)
        return String(format: "%.1f", avg)
    }

    // MARK: - Stats Section

    private func statsSection(user: UserStats) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Physical Stats")
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.md) {
                StatCard(
                    label: "Height",
                    value: "\(Int(user.heightCm))",
                    unit: "cm",
                    icon: "ruler"
                )

                StatCard(
                    label: "Weight",
                    value: String(format: "%.1f", user.weightKg),
                    unit: "kg",
                    icon: "scalemass"
                )
            }

            // BMI card
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("BMI")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(String(format: "%.1f", user.bmi))
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(bmiColor(user.bmiCategory))

                    Text(user.bmiCategory.rawValue)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(bmiColor(user.bmiCategory))
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(bmiColor(user.bmiCategory).opacity(0.2))
                        .cornerRadius(DesignSystem.CornerRadius.full)
                }

                // BMI scale
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background gradient
                        HStack(spacing: 0) {
                            Rectangle().fill(DesignSystem.Colors.warning) // Underweight
                            Rectangle().fill(DesignSystem.Colors.success) // Normal
                            Rectangle().fill(DesignSystem.Colors.warning) // Overweight
                            Rectangle().fill(DesignSystem.Colors.error) // Obese
                        }
                        .frame(height: 8)
                        .cornerRadius(4)

                        // Indicator
                        let bmiPosition = min(max((user.bmi - 15) / 25, 0), 1) // 15-40 range
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .shadow(radius: 2)
                            .offset(x: geometry.size.width * bmiPosition - 8)
                    }
                }
                .frame(height: 16)

                HStack {
                    Text("15")
                    Spacer()
                    Text("25")
                    Spacer()
                    Text("40")
                }
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .glassCard()
        }
    }

    private func bmiColor(_ category: BMICategory) -> Color {
        switch category {
        case .underweight: return DesignSystem.Colors.warning
        case .normal: return DesignSystem.Colors.success
        case .overweight: return DesignSystem.Colors.warning
        case .obese: return DesignSystem.Colors.error
        }
    }

    // MARK: - Body Metrics Section

    private func bodyMetricsSection(user: UserStats) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Body Measurements")
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.textPrimary)

            VStack(spacing: DesignSystem.Spacing.sm) {
                MeasurementRow(label: "Neck", value: user.neckCm, unit: "cm")
                MeasurementRow(label: "Waist", value: user.waistCm, unit: "cm")
                MeasurementRow(label: "Shoulders", value: user.shoulderCm, unit: "cm")

                Divider()
                    .background(DesignSystem.Colors.surfaceTertiary)

                HStack {
                    Text("Waist-to-Shoulder Ratio")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(String(format: "%.2f", user.waistToShoulderRatio))
                        .font(DesignSystem.Typography.mono())
                        .foregroundColor(ratioColor(user.waistToShoulderRatio, gender: user.gender))
                }
            }
            .padding(DesignSystem.Spacing.md)
            .glassCard()
        }
    }

    private func ratioColor(_ ratio: Double, gender: Gender) -> Color {
        let ideal = gender == .male ? 0.6 : 0.7
        let deviation = abs(ratio - ideal)
        if deviation < 0.05 { return DesignSystem.Colors.success }
        if deviation < 0.1 { return DesignSystem.Colors.accentCyan }
        if deviation < 0.15 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("About")
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.textPrimary)

            VStack(spacing: 0) {
                InfoRow(label: "Version", value: "1.0.0")
                InfoRow(label: "Build", value: "1")
                InfoRow(label: "Framework", value: "Vision + SwiftData")
            }
            .glassCard()

            // Disclaimer
            Text("This app is for informational purposes only and is not a medical device. All recommendations are softmaxxing focused. Consult professionals for health concerns.")
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.warning.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.medium)
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Danger Zone")
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.error)

            Button {
                showResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Reset All Data")
                }
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.error)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.error.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Reset

    private func resetAllData() {
        // Delete all scans
        for scan in scans {
            modelContext.delete(scan)
        }

        // Delete all users
        for user in users {
            modelContext.delete(user)
        }

        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct ProfileStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Text(value)
                .font(DesignSystem.Typography.headline())
                .foregroundColor(DesignSystem.Colors.accentCyan)

            Text(label)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.accentCyan)

            HStack(alignment: .lastTextBaseline, spacing: DesignSystem.Spacing.xxs) {
                Text(value)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text(unit)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }

            Text(label)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .glassCard()
    }
}

struct MeasurementRow: View {
    let label: String
    let value: Double
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Spacer()

            Text("\(String(format: "%.1f", value)) \(unit)")
                .font(DesignSystem.Typography.mono())
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.mono())
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let user: UserStats

    @State private var age: String = ""
    @State private var selectedGender: Gender = .male
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var neckCm: String = ""
    @State private var waistCm: String = ""
    @State private var shoulderCm: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Personal Info
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Personal Info")
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.textPrimary)

                            OnboardingTextField(
                                icon: "calendar",
                                placeholder: "Age",
                                text: $age,
                                keyboardType: .numberPad
                            )
                            .padding(.horizontal, -DesignSystem.Spacing.lg)

                            // Gender selector
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    GenderButton(
                                        gender: gender,
                                        isSelected: selectedGender == gender
                                    ) {
                                        selectedGender = gender
                                    }
                                }
                            }
                        }

                        // Body Measurements
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Body Measurements")
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.textPrimary)

                            Group {
                                OnboardingTextField(
                                    icon: "ruler",
                                    placeholder: "Height (cm)",
                                    text: $heightCm,
                                    keyboardType: .numberPad
                                )

                                OnboardingTextField(
                                    icon: "scalemass",
                                    placeholder: "Weight (kg)",
                                    text: $weightKg,
                                    keyboardType: .decimalPad
                                )

                                OnboardingTextField(
                                    icon: "circle.dotted",
                                    placeholder: "Neck (cm)",
                                    text: $neckCm,
                                    keyboardType: .decimalPad
                                )

                                OnboardingTextField(
                                    icon: "circle",
                                    placeholder: "Waist (cm)",
                                    text: $waistCm,
                                    keyboardType: .decimalPad
                                )

                                OnboardingTextField(
                                    icon: "arrow.left.and.right",
                                    placeholder: "Shoulders (cm)",
                                    text: $shoulderCm,
                                    keyboardType: .decimalPad
                                )
                            }
                            .padding(.horizontal, -DesignSystem.Spacing.lg)
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.accentCyan)
                }
            }
            .onAppear {
                loadUserData()
            }
        }
    }

    private func loadUserData() {
        age = "\(user.age)"
        selectedGender = user.gender
        heightCm = "\(Int(user.heightCm))"
        weightKg = String(format: "%.1f", user.weightKg)
        neckCm = String(format: "%.1f", user.neckCm)
        waistCm = String(format: "%.1f", user.waistCm)
        shoulderCm = String(format: "%.1f", user.shoulderCm)
    }

    private func saveChanges() {
        user.age = Int(age) ?? user.age
        user.gender = selectedGender
        user.heightCm = Double(heightCm) ?? user.heightCm
        user.weightKg = Double(weightKg) ?? user.weightKg
        user.neckCm = Double(neckCm) ?? user.neckCm
        user.waistCm = Double(waistCm) ?? user.waistCm
        user.shoulderCm = Double(shoulderCm) ?? user.shoulderCm
        user.updatedAt = Date()

        try? modelContext.save()
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserStats.self, ScanHistory.self], inMemory: true)
}
