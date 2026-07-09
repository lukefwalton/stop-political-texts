import XCTest
@testable import StopPoliticalSpamTexts

/// The onboarding verify step shows its success message only when its sample
/// still classifies as filtered under the shipped defaults. Pin that here so a
/// future rules/default change can't silently turn the verify step into a
/// confusing "wasn't flagged" result.
final class OnboardingVerificationTests: XCTestCase {

    func testSampleIsFilteredUnderShippedDefaults() {
        let result = PoliticalTextClassifier().classify(
            sender: "12345",
            body: OnboardingVerification.sampleText,
            config: .defaults
        )
        XCTAssertTrue(result.isFiltered)
    }
}
