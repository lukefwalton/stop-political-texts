import Foundation

/// Single source of truth for the iOS Settings copy that tells a user how to
/// turn on the message filter. Both the onboarding flow (`OnboardingView`) and
/// the in-app setup screen (`EnableInstructionsView`) read from here so the
/// wording can't drift the next time Apple renames this Settings flow.
enum SetupInstructions {
    /// Ordered setup steps for current iOS (iOS 26+). The Settings labels are
    /// wrapped in markdown emphasis; render with markdown (see `StepRow`) or
    /// use `plainSteps` for plain-text contexts.
    static let steps: [String] = [
        "Open **Settings**.",
        "Tap **Apps**, then **Messages**.",
        "Scroll to **Unknown Senders**.",
        "Tap **Text Message Filter**.",
        "Choose **Stop Political Spam Texts**."
    ]

    /// `steps` with the markdown emphasis stripped, for views that render plain
    /// `Text` rather than an `AttributedString`.
    static var plainSteps: [String] {
        steps.map { markdown in
            if let attributed = try? AttributedString(markdown: markdown) {
                return String(attributed.characters)
            }
            return markdown
        }
    }

    /// Current-iOS Settings breadcrumb to the filter picker.
    static let currentPath = "Settings > Apps > Messages > Unknown Senders > Text Message Filter"

    /// Where the filter picker lives on iOS versions before the Apps reshuffle.
    static let olderIOSPath = "On older iOS: Settings > Messages > Unknown & Spam"

    /// Fuller older-iOS fallback, including the legacy toggle name.
    static let olderIOSFallback = "On older iOS: Settings > Messages > Unknown & Spam, then turn on Filter Unknown Senders."

    /// One-line summary of the required action.
    static let requiredSetup = "Open Text Message Filter under Unknown Senders, then pick Stop Political Spam Texts."

    /// Note that the filter name may be truncated in the picker list.
    static let filterNameNote = "In the Text Message Filter list, Stop Political Spam Texts may appear as Stop Political Spam. Tap it so it shows a checkmark."

    /// Blunt one-liner on scope + destination, shared so the app and onboarding
    /// set the same expectation: unknown senders only, sorted to Junk (not blocked).
    static let scopeNote = "This only filters texts from unknown senders — never your contacts — and moves the likely-political ones to your Junk folder rather than blocking them."
}
