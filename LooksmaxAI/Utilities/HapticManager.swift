import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Centralized haptic feedback so tactile responses stay consistent across the
/// app. No-ops on platforms without UIKit haptics.
final class HapticManager {

    static let shared = HapticManager()

    private init() {}

    enum Impact {
        case light, medium, heavy, soft, rigid
    }

    /// A light selection/tap feedback.
    func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// Impact feedback of the given weight.
    func impact(_ style: Impact = .medium) {
        #if canImport(UIKit)
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light: generator = UIImpactFeedbackGenerator(style: .light)
        case .medium: generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy: generator = UIImpactFeedbackGenerator(style: .heavy)
        case .soft: generator = UIImpactFeedbackGenerator(style: .soft)
        case .rigid: generator = UIImpactFeedbackGenerator(style: .rigid)
        }
        generator.impactOccurred()
        #endif
    }

    /// Success notification feedback (e.g. completing a routine).
    func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    /// Warning notification feedback.
    func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    /// Error notification feedback.
    func error() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}
