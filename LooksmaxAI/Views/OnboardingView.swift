import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showOnboarding: Bool

    @State private var currentPage = 0
    @State private var age: String = ""
    @State private var selectedGender: Gender = .male
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var neckCm: String = ""
    @State private var waistCm: String = ""
    @State private var shoulderCm: String = ""

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(0..<4) { index in
                        Rectangle()
                            .fill(index <= currentPage ?
                                  DesignSystem.Colors.accentCyan :
                                  DesignSystem.Colors.surfaceTertiary)
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.lg)

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    personalInfoPage.tag(1)
                    bodyMeasurementsPage.tag(2)
                    disclaimerPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
            }
        }
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Logo/Icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.surfacePrimary)
                    .frame(width: 120, height: 120)

                Image(systemName: "faceid")
                    .font(.system(size: 50))
                    .foregroundStyle(DesignSystem.Colors.gradientCyan)
            }
            .cyanGlow(intensity: 0.4)

            VStack(spacing: DesignSystem.Spacing.md) {
                Text("LooksmaxAI")
                    .font(DesignSystem.Typography.display(36))
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("Analyze your facial features and get personalized routines to maximize your potential")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .primaryButton()
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
    }

    // MARK: - Personal Info Page

    private var personalInfoPage: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Text("Personal Info")
                .font(DesignSystem.Typography.headline())
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.top, DesignSystem.Spacing.xl)

            Text("We'll use this to calculate your metrics")
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.md) {
                // Age
                OnboardingTextField(
                    icon: "calendar",
                    placeholder: "Age",
                    text: $age,
                    keyboardType: .numberPad
                )

                // Gender
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Gender")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)

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
                .padding(.horizontal, DesignSystem.Spacing.md)

                // Height
                OnboardingTextField(
                    icon: "ruler",
                    placeholder: "Height (cm)",
                    text: $heightCm,
                    keyboardType: .numberPad
                )

                // Weight
                OnboardingTextField(
                    icon: "scalemass",
                    placeholder: "Weight (kg)",
                    text: $weightKg,
                    keyboardType: .decimalPad
                )
            }
            .padding(.top, DesignSystem.Spacing.lg)

            Spacer()

            HStack(spacing: DesignSystem.Spacing.md) {
                Button {
                    withAnimation { currentPage = 0 }
                } label: {
                    Text("Back")
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .cornerRadius(DesignSystem.CornerRadius.full)
                }

                Button {
                    withAnimation { currentPage = 2 }
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .primaryButton(isEnabled: isPersonalInfoValid)
                .disabled(!isPersonalInfoValid)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
    }

    // MARK: - Body Measurements Page

    private var bodyMeasurementsPage: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Text("Body Measurements")
                .font(DesignSystem.Typography.headline())
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.top, DesignSystem.Spacing.xl)

            Text("For body composition scoring")
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.md) {
                OnboardingTextField(
                    icon: "circle.dotted",
                    placeholder: "Neck circumference (cm)",
                    text: $neckCm,
                    keyboardType: .decimalPad
                )

                OnboardingTextField(
                    icon: "circle",
                    placeholder: "Waist circumference (cm)",
                    text: $waistCm,
                    keyboardType: .decimalPad
                )

                OnboardingTextField(
                    icon: "arrow.left.and.right",
                    placeholder: "Shoulder width (cm)",
                    text: $shoulderCm,
                    keyboardType: .decimalPad
                )

                // Helper text
                Text("Measure at the widest points")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .padding(.top, DesignSystem.Spacing.xs)
            }
            .padding(.top, DesignSystem.Spacing.lg)

            Spacer()

            HStack(spacing: DesignSystem.Spacing.md) {
                Button {
                    withAnimation { currentPage = 1 }
                } label: {
                    Text("Back")
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .cornerRadius(DesignSystem.CornerRadius.full)
                }

                Button {
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .primaryButton(isEnabled: isBodyMeasurementsValid)
                .disabled(!isBodyMeasurementsValid)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
    }

    // MARK: - Disclaimer Page

    private var disclaimerPage: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(DesignSystem.Colors.warning)
                .padding(.top, DesignSystem.Spacing.xl)

            Text("Medical Disclaimer")
                .font(DesignSystem.Typography.headline())
                .foregroundColor(DesignSystem.Colors.textPrimary)

            ScrollView {
                Text(disclaimerText)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .padding(DesignSystem.Spacing.lg)
                    .glassCard()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)

            Spacer()

            HStack(spacing: DesignSystem.Spacing.md) {
                Button {
                    withAnimation { currentPage = 2 }
                } label: {
                    Text("Back")
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .cornerRadius(DesignSystem.CornerRadius.full)
                }

                Button {
                    saveUserAndContinue()
                } label: {
                    Text("I Understand")
                        .frame(maxWidth: .infinity)
                }
                .primaryButton()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
    }

    // MARK: - Validation

    private var isPersonalInfoValid: Bool {
        guard let ageInt = Int(age), ageInt >= 13 && ageInt <= 100 else { return false }
        guard let height = Double(heightCm), height >= 100 && height <= 250 else { return false }
        guard let weight = Double(weightKg), weight >= 30 && weight <= 300 else { return false }
        return true
    }

    private var isBodyMeasurementsValid: Bool {
        guard let neck = Double(neckCm), neck >= 20 && neck <= 60 else { return false }
        guard let waist = Double(waistCm), waist >= 40 && waist <= 200 else { return false }
        guard let shoulder = Double(shoulderCm), shoulder >= 30 && shoulder <= 200 else { return false }
        return true
    }

    // MARK: - Save

    private func saveUserAndContinue() {
        let userStats = UserStats(
            age: Int(age) ?? 25,
            gender: selectedGender,
            heightCm: Double(heightCm) ?? 175,
            weightKg: Double(weightKg) ?? 75,
            neckCm: Double(neckCm) ?? 38,
            waistCm: Double(waistCm) ?? 82,
            shoulderCm: Double(shoulderCm) ?? 115
        )

        modelContext.insert(userStats)

        try? modelContext.save()

        withAnimation {
            showOnboarding = false
        }
    }

    // MARK: - Disclaimer Text

    private var disclaimerText: String {
        """
        This app is for entertainment and informational purposes only. It is NOT a medical device and should NOT be used for medical diagnosis, treatment, or health decisions.

        All recommendations provided are "softmaxxing" techniques focused on natural grooming, fitness, and lifestyle improvements.

        Important:
        • Results are algorithmic estimates, not medical assessments
        • Facial analysis has inherent limitations
        • Beauty standards are subjective and culturally influenced
        • Self-worth is not determined by any score

        Consult healthcare professionals for any health-related concerns. By using this app, you acknowledge these limitations and agree that the developers are not liable for any decisions made based on this app's output.

        Based on community standards from Looksmaxxing.org and related research.
        """
    }
}

// MARK: - Supporting Views

struct OnboardingTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.accentCyan)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surfaceSecondary)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.surfaceTertiary, lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

struct GenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(gender.rawValue)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(isSelected ?
                                 DesignSystem.Colors.background :
                                 DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    isSelected ?
                    DesignSystem.Colors.accentCyan :
                    DesignSystem.Colors.surfaceSecondary
                )
                .cornerRadius(DesignSystem.CornerRadius.full)
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .modelContainer(for: UserStats.self, inMemory: true)
}
