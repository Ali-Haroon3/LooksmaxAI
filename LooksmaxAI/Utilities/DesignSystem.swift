import SwiftUI

/// Design System: High-tech Dark Mode aesthetic
/// Deep blacks, slate grays, neon blue/cyan accents
enum DesignSystem {

    // MARK: - Colors

    enum Colors {
        // Primary backgrounds
        static let background = Color(hex: "0A0A0F")
        static let surfacePrimary = Color(hex: "12121A")
        static let surfaceSecondary = Color(hex: "1A1A25")
        static let surfaceTertiary = Color(hex: "252535")

        // Accent colors
        static let accentCyan = Color(hex: "00D4FF")
        static let accentBlue = Color(hex: "3B82F6")
        static let accentPurple = Color(hex: "8B5CF6")
        static let accentPink = Color(hex: "EC4899")

        // Status colors
        static let success = Color(hex: "10B981")
        static let warning = Color(hex: "F59E0B")
        static let error = Color(hex: "EF4444")

        // Text colors
        static let textPrimary = Color(hex: "FFFFFF")
        static let textSecondary = Color(hex: "A1A1AA")
        static let textTertiary = Color(hex: "71717A")

        // Gradient presets
        static let gradientCyan = LinearGradient(
            colors: [Color(hex: "00D4FF"), Color(hex: "0099CC")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let gradientPurple = LinearGradient(
            colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let gradientScore = LinearGradient(
            colors: [Color(hex: "00D4FF"), Color(hex: "8B5CF6")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Typography

    enum Typography {
        static func display(_ size: CGFloat = 48) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }

        static func headline(_ size: CGFloat = 24) -> Font {
            .system(size: size, weight: .semibold, design: .default)
        }

        static func title(_ size: CGFloat = 18) -> Font {
            .system(size: size, weight: .semibold, design: .default)
        }

        static func body(_ size: CGFloat = 16) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }

        static func caption(_ size: CGFloat = 14) -> Font {
            .system(size: size, weight: .medium, design: .default)
        }

        static func mono(_ size: CGFloat = 14) -> Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 999
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.large

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.Colors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

struct CyanGlow: ViewModifier {
    var intensity: CGFloat = 0.5

    func body(content: Content) -> some View {
        content
            .shadow(color: DesignSystem.Colors.accentCyan.opacity(intensity), radius: 8, x: 0, y: 0)
            .shadow(color: DesignSystem.Colors.accentCyan.opacity(intensity * 0.5), radius: 16, x: 0, y: 0)
    }
}

struct PrimaryButton: ViewModifier {
    var isEnabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(DesignSystem.Typography.title())
            .foregroundColor(DesignSystem.Colors.background)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                isEnabled ? DesignSystem.Colors.gradientCyan : LinearGradient(
                    colors: [DesignSystem.Colors.textTertiary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.full)
            .modifier(CyanGlow(intensity: isEnabled ? 0.3 : 0))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = DesignSystem.CornerRadius.large) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func cyanGlow(intensity: CGFloat = 0.5) -> some View {
        modifier(CyanGlow(intensity: intensity))
    }

    func primaryButton(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButton(isEnabled: isEnabled))
    }
}

// MARK: - Score Color Helper

extension Double {
    var scoreColor: Color {
        switch self {
        case 0..<3: return DesignSystem.Colors.error
        case 3..<5: return DesignSystem.Colors.warning
        case 5..<7: return Color(hex: "84CC16")  // Lime
        case 7..<8.5: return DesignSystem.Colors.accentCyan
        default: return DesignSystem.Colors.accentPurple
        }
    }
}
