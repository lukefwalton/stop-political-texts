import Foundation

/// The built-in classifier knowledge: weighted rules, hard-political markers,
/// and the critical allowlist. This is the only place term lists live, so the
/// app and the extension always agree. There are no candidate-name lists.
enum RuleSet {

    // MARK: - Shared markers

    /// Party / committee acronyms that are both stand-alone instant-filter
    /// markers (`hardPoliticalTerms`) and weighted organization signals
    /// (`politicalOrg`). Declared once so the two lists can't drift apart.
    static let partyCommitteeMarkers: [String] = ["dnc", "rnc", "nrcc", "dccc"]

    /// The MAGA slogan, used both as an instant-filter marker and a slogan
    /// signal (`politicalSlogan`). Declared once for the same reason.
    static let magaSlogan: [String] = ["maga", "make america great again"]

    // MARK: - Hard political (immediate filter, score floor 8)

    /// Platform / org markers that filter on their own whenever enabled.
    static let hardPoliticalTerms: [String] =
        ["actblue", "winred"] + partyCommitteeMarkers + magaSlogan

    /// Known fundraising / party domains. A host match is hard political.
    /// Limited to unambiguously-political party/committee and fundraising-platform
    /// domains; generic CRM/texting vendors are intentionally excluded to avoid
    /// false positives on nonprofit/civic traffic.
    static let politicalDomains: [String] = [
        "secure.actblue.com", "actblue.com",
        "secure.winred.com", "winred.com",
        "dnc.org", "gop.com", "nrcc.org", "dccc.org",
        "dscc.org", "nrsc.org"
    ]

    static let urlShorteners: [String] = [
        "bit.ly", "tinyurl.com", "t.co", "shorturl.at", "linktr.ee"
    ]

    // MARK: - Weighted rules

    static let rules: [Rule] = [
        Rule(
            id: "politicalOrg",
            displayName: "Political organization",
            terms: [
                "democrat", "democrats", "democratic", "republican", "republicans",
                "gop"
            ] + partyCommitteeMarkers + [
                "pac", "super pac", "grassroots",
                "campaign committee", "senate democrats", "house democrats",
                "house republicans", "senate republicans",
                "congressional republicans", "congressional democrats",
                // FEC-mandated disclaimers are near-perfect campaign-SMS markers.
                "paid for by", "not authorized by any candidate"
            ],
            weight: 4,
            category: .politicalOrganization
        ),
        Rule(
            id: "politicalSlogan",
            displayName: "Political slogan",
            terms: magaSlogan + ["blue wave", "red wave"],
            weight: 4,
            category: .politicalSlogan
        ),
        Rule(
            id: "electionTerms",
            displayName: "Election terms",
            terms: [
                "election", "vote", "voter", "voters", "voting", "ballot", "poll",
                "polling", "primary", "senate", "congress", "congressional",
                "campaign", "endorse", "endorsement", "election day", "early voting",
                "absentee ballot", "mail-in ballot", "mail in ballot"
            ],
            weight: 3,
            category: .electionTerms
        ),
        Rule(
            id: "fundraising",
            displayName: "Fundraising",
            terms: [
                "donate", "donation", "donor", "donors", "chip in", "contribute",
                "contribution", "match", "matching", "deadline", "midnight",
                "fundraising", "fundraiser", "grassroots donor", "rush",
                "before midnight", "triple match", "quadruple match",
                "700% match", "800% match"
            ],
            weight: 3,
            category: .fundraising
        ),
        // Ballot measures split into noun + directional rules so a directional
        // call paired with a measure noun reaches the Normal threshold. Both
        // require pairing with another signal (see SeamS in the spec).
        Rule(
            id: "ballotMeasureNoun",
            displayName: "Ballot measure",
            terms: [
                "proposition", "prop", "ballot measure", "measure", "initiative",
                "referendum", "recall", "amendment", "constitutional amendment",
                "bond measure"
            ],
            weight: 3,
            category: .ballotMeasure,
            requiresPairing: true
        ),
        Rule(
            id: "ballotMeasureAction",
            displayName: "Ballot directive",
            terms: [
                "yes on", "no on", "vote yes", "vote no", "support prop",
                "oppose prop", "defeat prop", "protect prop", "signature drive",
                "canvass", "get out the vote", "gotv", "mail ballot"
            ],
            weight: 3,
            category: .ballotMeasure,
            requiresPairing: true
        ),
        Rule(
            id: "mobilization",
            displayName: "Mobilization",
            terms: [
                "petition", "volunteer", "rally", "town hall", "can we count on you",
                "sign now", "pledge", "phone bank", "door knock"
            ],
            weight: 2,
            category: .mobilization
        ),
        Rule(
            id: "campaignSurveys",
            displayName: "Campaign survey",
            terms: [
                "take our survey", "official survey", "take this survey",
                "political survey", "official poll", "respond yes", "reply yes",
                "are you voting", "who are you voting", "who has your vote"
            ],
            weight: 3,
            category: .campaignSurveys
        ),
        Rule(
            id: "smsMechanics",
            displayName: "SMS mechanics",
            terms: [
                "reply stop", "stop to end", "stop2end", "txt stop", "text stop",
                "msg&data rates", "message and data rates", "msg frequency",
                "reply help", "opt out", "unsubscribe"
            ],
            weight: 2,
            category: .smsMechanics
        )
    ]

    static func enabledRules(_ toggles: CategoryToggles) -> [Rule] {
        rules.filter { $0.category.isEnabled(in: toggles) }
    }

    // MARK: - Critical allowlist

    /// Auth/security phrases. Presence allows the message (unless hard political).
    static let authAllowlist: [String] = [
        "verification code", "security code", "login code", "authentication code",
        "2fa", "two-factor", "two factor", "one-time code", "one time code",
        "password reset", "account recovery"
    ]

    /// Tightened auth regex: a numeric code not embedded in an alphanumeric token.
    /// Rejects political "codes" like MAGA2026 (digits abut letters).
    static let authCodeRegex: NSRegularExpression? = {
        let pattern = "(?i)\\b(verification|security|login|authentication|one[- ]?time|password reset)?\\s*(code|pin|otp)\\s*(is|:)?\\s*(?<![a-z0-9])\\d{4,8}(?![a-z0-9])"
        return try? NSRegularExpression(pattern: pattern)
    }()

    /// Commerce-shape phrases. Single bare nouns like `"order"`, `"gate"`, or
    /// `"bank"` are intentionally NOT here — they appear too readily in
    /// fundraising texts ("order your yard sign", "phone bank") and would
    /// allowlist messages the classifier is supposed to score. Each entry is a
    /// phrase that signals a real transaction/appointment context.
    static let commerceAllowlist: [String] = [
        "your order", "order #", "order is", "order has", "order ready",
        "delivered", "delivery", "shipment", "shipped", "tracking",
        "receipt", "appointment", "reservation",
        "boarding gate", "gate changed", "flight", "boarding pass",
        "prescription", "pharmacy",
        "bank alert", "from your bank", "card ending", "transaction",
        "fraud alert", "doctor", "dentist", "restaurant", "rideshare",
        "uber", "lyft", "doordash", "amazon", "ups", "fedex", "usps"
    ]

    static let emergencyAllowlist: [String] = [
        "emergency alert", "evacuation", "amber alert", "weather alert",
        "public safety", "wildfire", "earthquake", "flood warning"
    ]

    /// Official election-administration phrases: the transactional ballot-status
    /// confirmations county election offices send (BallotTrax-style). Every entry
    /// is a past-tense confirmation that something already happened to *your*
    /// ballot — never a call to action — so GOTV spam built on the same nouns
    /// ("your ballot has not been received — vote now!") still scores normally.
    /// Like the other allowlists, a hard-political marker still overrides.
    static let electionAdminAllowlist: [String] = [
        "ballot has been received", "ballot was received",
        "ballot has been counted", "ballot was counted",
        "ballot has been accepted", "ballot was accepted",
        "we have received your ballot", "we have counted your ballot",
        "we have accepted your ballot"
    ]

    /// True if the text trips any allowlist (auth phrase, auth code regex,
    /// commerce, emergency, or election administration).
    static func matchesCriticalAllowlist(_ normalizedText: String) -> Bool {
        let phraseLists = [authAllowlist, commerceAllowlist, emergencyAllowlist,
                           electionAdminAllowlist]
        for list in phraseLists {
            if list.contains(where: { TermMatcher.matches(term: $0, in: normalizedText) }) {
                return true
            }
        }
        if let regex = authCodeRegex {
            let range = NSRange(normalizedText.startIndex..., in: normalizedText)
            if regex.firstMatch(in: normalizedText, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }
}
