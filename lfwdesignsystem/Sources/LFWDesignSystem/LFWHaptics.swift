#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

/// The shared haptic vocabulary for the app family. One small semantic set so
/// every app speaks the same tactile language instead of each reaching for raw
/// `UIImpactFeedbackGenerator` in its own way:
///
/// - `selection()`  — a light tick when a value changes (toggles, pickers, reveals)
/// - `impact(_:)`   — committing an action (save a set, add a term, start a timer)
/// - `success()` / `warning()` / `failure()` — verdicts (parsed ok, limit hit, error)
///
/// Everything no-ops off UIKit (widgets, unit tests, non-iOS) so callers can fire
/// haptics unconditionally. Generators are created per call — cheap for discrete,
/// user-initiated taps; for continuous feedback hold your own generator instead.
public enum LFWHaptics {

    /// Impact weight, mirroring `UIImpactFeedbackGenerator.FeedbackStyle`.
    public enum Impact {
        case light, medium, heavy, soft, rigid

        #if canImport(UIKit)
        var style: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light:  return .light
            case .medium: return .medium
            case .heavy:  return .heavy
            case .soft:   return .soft
            case .rigid:  return .rigid
            }
        }
        #endif
    }

    /// A light selection tick — for a value changing (toggle flip, picker move,
    /// tap-to-reveal). The most common tap; keep it subtle.
    public static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// A committing tap — the user did a thing that "lands" (save, add, delete,
    /// start). Defaults to `.light`; use `.medium`/`.rigid` for weightier commits.
    public static func impact(_ weight: Impact = .light) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: weight.style).impactOccurred()
        #endif
    }

    /// A positive verdict — an operation succeeded (workout saved, message allowed).
    public static func success() { notify(.success) }

    /// A cautionary verdict — a soft limit or non-fatal block (term cap reached).
    public static func warning() { notify(.warning) }

    /// A negative verdict — something failed (parse error, save failed).
    public static func failure() { notify(.error) }

    #if canImport(UIKit)
    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    #else
    private static func notify(_ type: Int) {}
    #endif
}
