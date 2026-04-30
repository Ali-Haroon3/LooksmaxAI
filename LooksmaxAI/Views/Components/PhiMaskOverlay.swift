import SwiftUI

/// A decorative golden-ratio grid overlay drawn on top of a captured face
/// photo. Renders horizontal and vertical phi division lines plus a summary
/// harmony badge.
struct PhiMaskOverlay: View {
    let report: GoldenRatio.HarmonyReport
    var lineColor: Color = DesignSystem.Colors.accentCyan

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                phiGrid(in: geo.size)
                harmonyBadge
                    .padding(DesignSystem.Spacing.sm)
            }
        }
    }

    private func phiGrid(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let stroke = GraphicsContext.Shading.color(lineColor.opacity(0.5))

            // Vertical golden divisions (from both edges).
            let vMajor = GoldenRatio.goldenSegments(of: canvasSize.width).major
            for x in [vMajor, canvasSize.width - vMajor] {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                context.stroke(path, with: stroke, lineWidth: 1)
            }

            // Horizontal golden divisions.
            let hMajor = GoldenRatio.goldenSegments(of: canvasSize.height).major
            for y in [hMajor, canvasSize.height - hMajor] {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                context.stroke(path, with: stroke, lineWidth: 1)
            }
        }
    }

    private var harmonyBadge: some View {
        VStack(spacing: 2) {
            Text("\(report.overallPercentage)%")
                .font(DesignSystem.Typography.mono(18))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text("φ harmony")
                .font(DesignSystem.Typography.caption(11))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.Colors.surfacePrimary.opacity(0.85))
        )
        .cyanGlow(intensity: 0.25)
    }
}
