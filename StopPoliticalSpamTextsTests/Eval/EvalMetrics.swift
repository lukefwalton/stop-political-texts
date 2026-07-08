import Foundation
@testable import StopPoliticalSpamTexts

/// The classifier's verdict on one eval case under one strictness mode.
struct EvalCaseResult {
    let evalCase: EvalCase
    let isFiltered: Bool
    let expectedFiltered: Bool

    var passed: Bool { isFiltered == expectedFiltered }
    var isFalsePositive: Bool { isFiltered && !expectedFiltered }
    var isFalseNegative: Bool { !isFiltered && expectedFiltered }
}

/// One full evaluation of the corpus under one strictness mode, plus the
/// derived metrics. Pure computation — no XCTest, no I/O — so it can back
/// both the assertions and the printed report.
struct EvalRun {
    let strictness: Strictness
    let results: [EvalCaseResult]

    var truePositives: Int { results.filter { $0.expectedFiltered && $0.isFiltered }.count }
    var falsePositives: Int { results.filter(\.isFalsePositive).count }
    var falseNegatives: Int { results.filter(\.isFalseNegative).count }
    var trueNegatives: Int { results.filter { !$0.expectedFiltered && !$0.isFiltered }.count }

    var precision: Double { ratio(truePositives, truePositives + falsePositives) }
    var recall: Double { ratio(truePositives, truePositives + falseNegatives) }
    var f1: Double {
        let denominator = precision + recall
        return denominator == 0 ? 0 : 2 * precision * recall / denominator
    }

    var failingIDs: Set<String> {
        Set(results.filter { !$0.passed }.map(\.evalCase.id))
    }

    /// Recall per positive category (categories with at least one expected
    /// positive), as (hits, total).
    var recallByCategory: [(category: String, hits: Int, total: Int)] {
        grouped(\.evalCase.category, where: \.expectedFiltered)
    }

    /// Recall per party label, positives only.
    var recallByParty: [(category: String, hits: Int, total: Int)] {
        grouped(\.evalCase.party, where: \.expectedFiltered)
    }

    /// Recall per adversarial technique, positives only.
    var recallByTechnique: [(category: String, hits: Int, total: Int)] {
        grouped({ $0.evalCase.technique ?? "" }, where: \.expectedFiltered)
            .filter { !$0.category.isEmpty }
    }

    /// False-positive counts per negative category (only categories with FPs).
    var falsePositivesByCategory: [(category: String, count: Int)] {
        var counts: [String: Int] = [:]
        for result in results where result.isFalsePositive {
            counts[result.evalCase.category, default: 0] += 1
        }
        return counts.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    /// Recall as a fraction for each party that has at least `minimumPositives`
    /// expected positives. Used by the party-bias backstop assertion.
    func partyRecalls(minimumPositives: Int) -> [String: Double] {
        var recalls: [String: Double] = [:]
        for entry in recallByParty where entry.total >= minimumPositives {
            recalls[entry.category] = ratio(entry.hits, entry.total)
        }
        return recalls
    }

    private func grouped(
        _ key: (EvalCaseResult) -> String,
        where include: (EvalCaseResult) -> Bool
    ) -> [(category: String, hits: Int, total: Int)] {
        var totals: [String: Int] = [:]
        var hits: [String: Int] = [:]
        for result in results where include(result) {
            let bucket = key(result)
            totals[bucket, default: 0] += 1
            if result.isFiltered { hits[bucket, default: 0] += 1 }
        }
        return totals.sorted { $0.key < $1.key }.map { ($0.key, hits[$0.key] ?? 0, $0.value) }
    }

    private func ratio(_ numerator: Int, _ denominator: Int) -> Double {
        denominator == 0 ? 1.0 : Double(numerator) / Double(denominator)
    }
}

enum EvalHarness {

    static func config(strictness: Strictness) -> FilterConfig {
        var config = FilterConfig.defaults
        config.strictness = strictness
        return config
    }

    /// Classifies every case under the given strictness with default toggles
    /// and no custom terms — the same configuration shape the extension runs.
    static func run(cases: [EvalCase], strictness: Strictness) -> EvalRun {
        let classifier = PoliticalTextClassifier()
        let config = config(strictness: strictness)
        let results = cases.map { evalCase -> EvalCaseResult in
            let outcome = classifier.classify(
                sender: evalCase.sender,
                body: evalCase.body,
                config: config
            )
            return EvalCaseResult(
                evalCase: evalCase,
                isFiltered: outcome.isFiltered,
                expectedFiltered: evalCase.expect.outcome(for: strictness) == .filtered
            )
        }
        return EvalRun(strictness: strictness, results: results)
    }

    /// Renders the metrics table. Every line is prefixed so CI can grep the
    /// report out of the xcodebuild log:  grep 'EVAL-METRICS |'
    static func report(runs: [EvalRun]) -> String {
        var lines: [String] = []
        for run in runs {
            lines.append("================ classifier eval (\(run.strictness.rawValue)) ================")
            lines.append("cases=\(run.results.count) TP=\(run.truePositives) FP=\(run.falsePositives) "
                + "FN=\(run.falseNegatives) TN=\(run.trueNegatives)")
            lines.append("precision=\(format(run.precision)) recall=\(format(run.recall)) f1=\(format(run.f1))")
            lines.append("recall by party:      " + formatFractions(run.recallByParty))
            lines.append("recall by category:   " + formatFractions(run.recallByCategory))
            lines.append("recall by technique:  " + formatFractions(run.recallByTechnique))
            let fps = run.falsePositivesByCategory
            lines.append("false positives:      " + (fps.isEmpty ? "none"
                : fps.map { "\($0.category)=\($0.count)" }.joined(separator: "  ")))
            let failures = run.failingIDs.sorted()
            lines.append("failing cases (\(failures.count)): "
                + (failures.isEmpty ? "none" : failures.joined(separator: " ")))
        }
        return lines.map { "EVAL-METRICS | \($0)" }.joined(separator: "\n")
    }

    /// The paste-ready baseline JSON for the current outcomes, printed by the
    /// baseline assertion when it fails so the fix is a copy-paste.
    static func baselineJSON(aggressive: Set<String>, normal: Set<String>) -> String {
        let baseline = EvalBaseline(
            schemaVersion: EvalCorpus.supportedSchemaVersion,
            knownFailures: EvalBaseline.KnownFailures(
                aggressive: aggressive.sorted(),
                normal: normal.sorted()
            )
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(baseline),
              let json = String(data: data, encoding: .utf8) else {
            return "<encoding failed>"
        }
        return json
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.4f", value)
    }

    private static func formatFractions(_ entries: [(category: String, hits: Int, total: Int)]) -> String {
        entries.isEmpty ? "none" : entries
            .map { "\($0.category)=\($0.hits)/\($0.total)" }
            .joined(separator: "  ")
    }
}
