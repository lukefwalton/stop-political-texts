import XCTest
@testable import StopPoliticalSpamTexts

/// Covers the three-way branch that powers `StillGettingTextsView`: given a
/// classification of a text the user *still received*, which problem is it?
final class SetupDiagnosisTests: XCTestCase {

    private let classifier = PoliticalTextClassifier()

    /// A message the rules catch that still arrived means the OS-level filter
    /// isn't selected in iOS Settings.
    func testFilteredTextDiagnosesAsNotActiveInSettings() {
        let result = classifier.classify(
            sender: "12345",
            body: "Paid for by Friends of Jane. Donate $25 before midnight — reply STOP to opt out.",
            config: .defaults
        )
        XCTAssertTrue(result.isFiltered)
        XCTAssertEqual(SetupDiagnosis(result: result), .notActiveInSettings)
    }

    /// The in-app toggle being off short-circuits to `reason == "disabled"`.
    func testDisabledInAppTogglesDiagnosesAsDisabled() {
        var config = FilterConfig.defaults
        config.enabled = false
        let result = classifier.classify(
            sender: "12345",
            body: "ActBlue: donate before midnight to help us win!",
            config: config
        )
        XCTAssertFalse(result.isFiltered)
        XCTAssertEqual(result.reason, "disabled")
        XCTAssertEqual(SetupDiagnosis(result: result), .disabledInApp)
    }

    /// Filtering is on and ran, but the message scored below the bar — a genuine
    /// coverage gap, not a setup problem.
    func testBelowThresholdTextDiagnosesAsClassifierGap() {
        let result = classifier.classify(
            sender: nil,
            body: "Hey, are we still on for dinner tomorrow night?",
            config: .defaults
        )
        XCTAssertFalse(result.isFiltered)
        XCTAssertNotEqual(result.reason, "disabled")
        XCTAssertEqual(SetupDiagnosis(result: result), .classifierGap)
    }
}
