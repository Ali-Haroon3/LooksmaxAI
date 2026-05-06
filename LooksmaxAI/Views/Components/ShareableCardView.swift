import SwiftUI

/// A polished, screenshot-friendly summary card of a scan result, designed to
/// be rendered to an image via `ImageRenderer` and shared.
struct ShareableCardView: View {
    let scan: ScanHistory

    private var report: ReportGenerator.Report {
        ReportGenerator.makeReport(for: scan)
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            header
            scoreDial
            breakdown
            footer
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(width: 320)
        .background(DesignSystem.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
    }

    private var header: some View {
        HStack {
            Image(systemName: "waveform.path.ecg")
                .foregroundColor(DesignSystem.Colors.accentCyan)
            Text("LOOKSMAX AI")
                .font(DesignSystem.Typography.caption(13))
                .tracking(2)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(shortDate)
                .font(DesignSystem.Typography.caption(12))
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
    }

    private var scoreDial: some View {
        VStack(spacing: 2) {
            Text(report.headlineScore.replacingOccurrences(of: " / 10", with: ""))
                .font(DesignSystem.Typography.display(64))
                .foregroundStyle(DesignSystem.Colors.gradientScore)
            Text(report.category)
                .font(DesignSystem.Typography.title())
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    private var breakdown: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(report.lines.prefix(4), id: \.label) { line in
                HStack {
                    Text(line.label)
                        .font(DesignSystem.Typography.caption(13))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text(line.value)
                        .font(DesignSystem.Typography.mono(13))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
    }

    private var footer: some View {
        Text(report.disclaimer)
            .font(DesignSystem.Typography.caption(10))
            .foregroundColor(DesignSystem.Colors.textTertiary)
            .multilineTextAlignment(.center)
    }

    private var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: scan.scannedAt)
    }
}

// MARK: - Rendering Helper

#if canImport(UIKit)
import UIKit

extension ShareableCardView {
    /// Render the card to a `UIImage` suitable for the share sheet.
    @MainActor
    func renderedImage(scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        return renderer.uiImage
    }
}
#endif
