import XCTest
@testable import StopPoliticalSpamTexts

/// Guard tests for `RuleSet.rules` shape.
///
/// `MatchedRuleLabels.friendly(for:)` calls
/// `Dictionary(uniqueKeysWithValues: RuleSet.rules.map { ($0.id, $0.displayName) })`
/// which **traps** on duplicate keys. A duplicate `Rule.id` slipping in
/// would crash the test message screen at first render. Catch it here.
final class RuleSetTests: XCTestCase {

    func testRuleIDsAreUnique() {
        let ids = RuleSet.rules.map(\.id)
        let unique = Set(ids)
        XCTAssertEqual(unique.count, ids.count,
                       "Rule.id values must be unique — TestMessageView uses them as a Dictionary key")
    }

    /// Every rule must carry a non-empty displayName so the UI never falls
    /// back to the raw id (which is the regression `displayName` exists to
    /// prevent).
    func testRuleDisplayNamesArePresent() {
        for rule in RuleSet.rules {
            XCTAssertFalse(rule.displayName.isEmpty,
                           "Rule \(rule.id) is missing a displayName")
        }
    }

    /// The synthetic-id namespace used by `TestMessageView`'s fallback dict
    /// must not collide with any `Rule.id` — otherwise the rule's label
    /// could be shadowed by the synthetic one in a future refactor.
    func testRuleIDsDoNotCollideWithSyntheticIDs() {
        let synthetic: Set<String> = [
            "hard_political", "sender_shortcode", "sender_10dlc",
            "url_shortener_strong", "url_shortener_political"
        ]
        let ruleIDs = Set(RuleSet.rules.map(\.id))
        XCTAssertTrue(ruleIDs.intersection(synthetic).isEmpty,
                      "A Rule.id collides with a synthetic id used by TestMessageView")
    }
}
