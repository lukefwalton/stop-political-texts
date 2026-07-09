import Foundation

/// Maps a `ClassificationResult` for a text the user *still received* onto the
/// kind of problem they have. Pure logic, split out from `StillGettingTextsView`
/// so the three-way branch can be unit-tested without SwiftUI.
///
/// The key insight: the app cannot read iOS Settings, so it cannot know whether
/// its extension is the selected SMS filter. But it *can* say what the classifier
/// would have done with the pasted text, and that alone separates the two failure
/// modes — a message the rules would catch that still arrived means the OS-level
/// filter is not active; a message the rules let through is a coverage gap.
enum SetupDiagnosis: Equatable {
    /// The classifier would have filtered this. Since it still reached the inbox,
    /// the filter almost certainly is not selected in iOS Settings.
    case notActiveInSettings
    /// The in-app Filtering toggle is off, so nothing is being scored.
    case disabledInApp
    /// Filtering is on and the rules ran, but this message scored below the bar.
    case classifierGap

    init(result: ClassificationResult) {
        if result.isFiltered {
            self = .notActiveInSettings
        } else if result.reason == "disabled" {
            self = .disabledInApp
        } else {
            self = .classifierGap
        }
    }
}
