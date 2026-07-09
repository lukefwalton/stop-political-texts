import Foundation

/// Human-readable names for the rule ids a `ClassificationResult` carries. Shared
/// by the message tester (`TestMessageView`) and the setup diagnostic
/// (`StillGettingTextsView`) so the id→label table lives in exactly one place.
///
/// The raw `internalScore` is never surfaced (DEBUG-only per
/// `PoliticalTextClassifier`); only these friendly labels are shown.
enum MatchedRuleLabels {

    /// Built-in rules carry their own `displayName`, so a newly added rule shows
    /// up correctly without a parallel table. Synthetic ids (hard-political
    /// shortcuts, sender/URL boosts, the user's custom terms) are not `Rule`
    /// instances — their labels live here.
    private static let syntheticNames: [String: String] = [
        "hard_political": "Known political platform",
        "sender_shortcode": "Short code sender",
        "sender_10dlc": "10-digit sender",
        "url_shortener_strong": "Shortened link",
        "url_shortener_political": "Shortened link",
        "deobfuscated": "Disguised wording"
    ]

    /// De-duplicated friendly labels for every matched rule, in match order.
    static func friendly(for result: ClassificationResult) -> [String] {
        let ruleNames: [String: String] = Dictionary(
            uniqueKeysWithValues: RuleSet.rules.map { ($0.id, $0.displayName) }
        )
        var seen = Set<String>()
        var names: [String] = []
        for id in result.matchedRules {
            let label: String
            if id.hasPrefix("custom_block:") {
                label = "Your blocked term"
            } else if id.hasPrefix("custom_allow:") {
                label = "Your allowed term"
            } else {
                label = ruleNames[id] ?? syntheticNames[id] ?? id
            }
            if seen.insert(label).inserted {
                names.append(label)
            }
        }
        return names
    }
}
