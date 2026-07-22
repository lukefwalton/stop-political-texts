import Foundation

/// A sample message and the outcome the classifier should produce. Shared by
/// the in-app verification screen, unit tests, and `scripts/review_demo.sh`.
struct ClassifierFixture: Equatable, Identifiable {
    enum Expectation: Equatable {
        /// Filtered in both Normal and Aggressive mode.
        case filtered
        /// Allowed in both Normal and Aggressive mode.
        case allowed
        /// Allowed in Normal mode; Aggressive may still filter.
        case allowedInNormalOnly
    }

    let id: String
    let label: String
    let body: String
    let sender: String?
    let expectation: Expectation

    init(
        id: String,
        label: String,
        body: String,
        sender: String? = nil,
        expectation: Expectation
    ) {
        self.id = id
        self.label = label
        self.body = body
        self.sender = sender
        self.expectation = expectation
    }
}

struct ClassifierFixtureResult: Equatable {
    let fixture: ClassifierFixture
    let isFiltered: Bool
    let expectedFiltered: Bool

    var passed: Bool { isFiltered == expectedFiltered }
}

/// Canonical sample corpus for App Review, QA, and CI.
enum ClassifierFixtures {

    /// Samples reviewers and QA can run without receiving real SMS.
    static let reviewCorpus: [ClassifierFixture] = [
        ClassifierFixture(
            id: "review_example",
            label: "App Review example",
            body: "Election deadline tonight. Donate now to help our campaign win. Reply STOP to opt out.",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "actblue",
            label: "Fundraising platform",
            body: "ActBlue donation link inside.",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "winred",
            label: "Fundraising platform",
            body: "WinRed: 700% match active now.",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "donate_dem",
            label: "Campaign fundraising",
            body: "Democrats need your help. Donate before midnight.",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "gop_vote",
            label: "Campaign election ask",
            body: "GOP alert: can we count on your vote?",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "election_poll",
            label: "Campaign poll",
            body: "Election poll: who are you voting for?",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "ballot_prop",
            label: "Ballot measure",
            body: "Vote yes on Prop 12 before Election Day.",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "pac_deadline",
            label: "PAC fundraising",
            body: "PAC deadline: chip in before midnight.",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "news_bait",
            label: "News-bait political blast",
            body: "Obama just inspired a House majority MIRACLE! Look at his MAJOR comeback: saveusadem.com/l/DNGV3y DemocracyHQ End2End",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "shortcode_fundraise",
            label: "Short code + fundraising",
            body: "Donate before midnight to help Democrats.",
            sender: "12345",
            expectation: .filtered
        ),
        ClassifierFixture(
            id: "verification_code",
            label: "2FA / verification",
            body: "Your verification code is 123456.",
            expectation: .allowed
        ),
        ClassifierFixture(
            id: "amazon_shipped",
            label: "Commerce shipping",
            body: "Your Amazon order has shipped.",
            expectation: .allowed
        ),
        ClassifierFixture(
            id: "bank_alert",
            label: "Bank alert",
            body: "Your bank alert: card ending 1234 was used.",
            expectation: .allowed
        ),
        ClassifierFixture(
            id: "magazine_substring",
            label: "Boundary: not political",
            body: "Check out this magazine article.",
            expectation: .allowed
        ),
        ClassifierFixture(
            id: "dnce_concert",
            label: "Boundary: DNC substring",
            body: "DNCE concert tickets on sale.",
            expectation: .allowed
        ),
        ClassifierFixture(
            id: "hoa_vote",
            label: "Non-campaign vote",
            body: "Please vote in the HOA survey.",
            expectation: .allowed
        ),
        ClassifierFixture(
            id: "office_campaign",
            label: "Non-political campaign",
            body: "The office campaign kickoff is tomorrow.",
            expectation: .allowed
        ),
    ]

    static func expectedFiltered(
        for fixture: ClassifierFixture,
        strictness: Strictness
    ) -> Bool {
        switch fixture.expectation {
        case .filtered:
            return true
        case .allowed:
            return false
        case .allowedInNormalOnly:
            return strictness == .aggressive
        }
    }

    static func evaluate(
        config: FilterConfig = .defaults,
        pipeline: (String?, String?, FilterConfig) -> ClassificationResult = { sender, body, config in
            PoliticalTextClassifier().classify(sender: sender, body: body, config: config)
        }
    ) -> [ClassifierFixtureResult] {
        reviewCorpus.map { fixture in
            let result = pipeline(fixture.sender, fixture.body, config)
            let expected = expectedFiltered(for: fixture, strictness: config.strictness)
            return ClassifierFixtureResult(
                fixture: fixture,
                isFiltered: result.isFiltered,
                expectedFiltered: expected
            )
        }
    }

    static func allPassed(config: FilterConfig = .defaults) -> Bool {
        evaluate(config: config).allSatisfy(\.passed)
    }

    /// Human-readable report for CI logs and pre-submit checks.
    static func report(config: FilterConfig = .defaults) -> String {
        let results = evaluate(config: config)
        let passed = results.filter(\.passed).count
        let total = results.count
        var lines = [
            "Stop Political Spam Texts — classifier verification",
            "Strictness: \(config.strictness.rawValue)  Enabled: \(config.enabled)",
            "Result: \(passed)/\(total) passed",
            ""
        ]
        for result in results {
            let mark = result.passed ? "PASS" : "FAIL"
            let outcome = result.isFiltered ? "Filtered" : "Allowed"
            let expected = result.expectedFiltered ? "Filtered" : "Allowed"
            lines.append("[\(mark)] \(result.fixture.label)")
            lines.append("       got \(outcome), expected \(expected)")
            if !result.passed {
                lines.append("       message: \"\(result.fixture.body)\"")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func failureSummary(config: FilterConfig = .defaults) -> String {
        evaluate(config: config)
            .filter { !$0.passed }
            .map { result in
                "\(result.fixture.id): got \(result.isFiltered ? "Filtered" : "Allowed"), "
                    + "expected \(result.expectedFiltered ? "Filtered" : "Allowed")"
            }
            .joined(separator: "\n")
    }
}
