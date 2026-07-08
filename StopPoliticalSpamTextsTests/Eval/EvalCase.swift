import Foundation
@testable import StopPoliticalSpamTexts

/// One labeled message in the eval corpus. Mirrors the schema of
/// `Eval/Resources/eval_corpus.json` (schemaVersion 1).
///
/// Unlike `ClassifierFixture` (whose expectation allows "Aggressive may
/// filter"), every eval case carries a definite authored label per strictness
/// mode — precision/recall need a ground truth, not a maybe.
struct EvalCase: Codable, Equatable {
    enum Outcome: String, Codable {
        case filtered
        case allowed
    }

    struct Expectation: Codable, Equatable {
        let aggressive: Outcome
        let normal: Outcome

        func outcome(for strictness: Strictness) -> Outcome {
            strictness == .aggressive ? aggressive : normal
        }
    }

    let id: String
    let body: String
    let sender: String?
    let expect: Expectation
    /// Closed vocabulary; see `EvalCorpus.categories`.
    let category: String
    /// Closed vocabulary; see `EvalCorpus.parties`. Positives are labeled
    /// dem/rep/nonpartisan/issue so recall can be compared across parties;
    /// negatives are "none".
    let party: String
    /// Obfuscation technique for adversarial cases; see `EvalCorpus.techniques`.
    let technique: String?
    /// For adversarial variants: the plain case this body was derived from.
    let baseId: String?
    /// Bias guard: every dem positive names its rep twin (same template,
    /// entities swapped) and vice versa.
    let pairId: String?
    /// Provenance. All cases are authored synthetic messages.
    let note: String
}

private struct EvalCorpusFile: Codable {
    let schemaVersion: Int
    let cases: [EvalCase]
}

/// Known-failure baseline. Mirrors `Eval/Resources/eval_baseline.json`.
/// The exact IDs of cases the classifier currently gets wrong, per strictness.
/// Regressions (new failures) AND silent improvements (stale entries) both
/// fail the suite until this file is updated, so every behavior change is a
/// reviewable diff.
struct EvalBaseline: Codable, Equatable {
    struct KnownFailures: Codable, Equatable {
        let aggressive: [String]
        let normal: [String]

        func ids(for strictness: Strictness) -> Set<String> {
            Set(strictness == .aggressive ? aggressive : normal)
        }
    }

    let schemaVersion: Int
    let knownFailures: KnownFailures
}

/// Anchor for `Bundle(for:)` — the test target is an XcodeGen unit-test
/// bundle, so `Bundle.module` is unavailable.
private final class EvalBundleToken {}

enum EvalCorpus {
    static let supportedSchemaVersion = 1

    /// Positive categories describe why a message is political spam; negative
    /// categories describe the legitimate traffic class the classifier must
    /// not touch. "review" is reserved for cases imported at runtime from
    /// `ClassifierFixtures.reviewCorpus`.
    static let categories: Set<String> = [
        "political_fundraising", "political_gotv", "political_survey",
        "political_mobilization", "ballot_measure",
        "auth", "commerce", "emergency",
        "charity_fundraising", "religious_school_fundraiser", "retail_urgency",
        "news_alert", "civic_noncampaign", "union_nonpolitical",
        "market_research", "gotv_adjacent_commercial",
        "boundary", "review"
    ]

    /// Categories whose false positives can never be baselined away: junking
    /// a 2FA code, bank alert, or evacuation notice is the worst failure the
    /// filter can produce.
    static let criticalNegativeCategories: Set<String> = [
        "auth", "commerce", "emergency"
    ]

    static let parties: Set<String> = ["dem", "rep", "nonpartisan", "issue", "none"]

    static let techniques: Set<String> = [
        "leet", "homoglyph", "zero_width", "punct_stuffing", "spaced_letters",
        "char_repeat", "diacritic", "fullwidth", "mixed"
    ]

    static func loadCases() throws -> [EvalCase] {
        let file: EvalCorpusFile = try decodeResource("eval_corpus")
        guard file.schemaVersion == supportedSchemaVersion else {
            throw EvalCorpusError.unsupportedSchema(file.schemaVersion)
        }
        return file.cases
    }

    static func loadBaseline() throws -> EvalBaseline {
        let baseline: EvalBaseline = try decodeResource("eval_baseline")
        guard baseline.schemaVersion == supportedSchemaVersion else {
            throw EvalCorpusError.unsupportedSchema(baseline.schemaVersion)
        }
        return baseline
    }

    /// The App Review fixtures, mapped into eval cases so the metrics report
    /// covers them without duplicating their data on disk. Their per-mode
    /// expectation is derived through the existing fixture semantics.
    static func reviewCorpusCases() -> [EvalCase] {
        ClassifierFixtures.reviewCorpus.map { fixture in
            EvalCase(
                id: "review:\(fixture.id)",
                body: fixture.body,
                sender: fixture.sender,
                expect: EvalCase.Expectation(
                    aggressive: ClassifierFixtures.expectedFiltered(for: fixture, strictness: .aggressive)
                        ? .filtered : .allowed,
                    normal: ClassifierFixtures.expectedFiltered(for: fixture, strictness: .normal)
                        ? .filtered : .allowed
                ),
                category: "review",
                party: "none",
                technique: nil,
                baseId: nil,
                pairId: nil,
                note: "Imported at runtime from ClassifierFixtures.reviewCorpus."
            )
        }
    }

    /// Everything the harness evaluates: the JSON corpus plus the imported
    /// review fixtures.
    static func allCases() throws -> [EvalCase] {
        try loadCases() + reviewCorpusCases()
    }

    private static func decodeResource<T: Decodable>(_ name: String) throws -> T {
        let bundle = Bundle(for: EvalBundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw EvalCorpusError.resourceMissing(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum EvalCorpusError: Error, CustomStringConvertible {
    case resourceMissing(String)
    case unsupportedSchema(Int)

    var description: String {
        switch self {
        case .resourceMissing(let name):
            return "Eval resource \(name).json is not in the test bundle — check the project.yml resources phase."
        case .unsupportedSchema(let version):
            return "Unsupported eval schema version \(version)."
        }
    }
}
