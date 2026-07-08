import XCTest
@testable import StopPoliticalSpamTexts

/// Regression harness for the eval corpus (`Eval/Resources/eval_corpus.json`).
///
/// The gate is an exact known-failures baseline (`eval_baseline.json`): any
/// NEW failing case fails the suite, and any case that starts passing while
/// still listed fails it too — improvements must land as a reviewed baseline
/// diff, never silently. Absolute floors back the baseline up: precision may
/// never drop below `precisionFloor`, and a false positive on auth, commerce,
/// or emergency traffic can never be baselined away.
final class EvalCorpusTests: XCTestCase {

    private static let precisionFloor = 0.98
    /// Max allowed recall gap between parties with at least
    /// `partyRecallMinimumPositives` expected positives. The pairwise check in
    /// `testPartyPairsGetIdenticalOutcomes` is the strong guard; this backstop
    /// covers drift against non-paired (nonpartisan) positives.
    private static let partyRecallMaxDelta = 0.10
    private static let partyRecallMinimumPositives = 10

    private var cases: [EvalCase] = []
    private var baseline: EvalBaseline!
    private var runs: [Strictness: EvalRun] = [:]

    override func setUpWithError() throws {
        try super.setUpWithError()
        cases = try EvalCorpus.allCases()
        baseline = try EvalCorpus.loadBaseline()
        for strictness in Strictness.allCases {
            runs[strictness] = EvalHarness.run(cases: cases, strictness: strictness)
        }
    }

    // MARK: - Structural validity

    func testCaseIDsAreUnique() {
        let ids = cases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate eval case ids")
    }

    func testVocabulariesAreClosed() {
        for evalCase in cases {
            XCTAssertTrue(
                EvalCorpus.categories.contains(evalCase.category),
                "\(evalCase.id): unknown category \(evalCase.category)"
            )
            XCTAssertTrue(
                EvalCorpus.parties.contains(evalCase.party),
                "\(evalCase.id): unknown party \(evalCase.party)"
            )
            if let technique = evalCase.technique {
                XCTAssertTrue(
                    EvalCorpus.techniques.contains(technique),
                    "\(evalCase.id): unknown technique \(technique)"
                )
            }
        }
    }

    func testPartisanCasesArePaired() throws {
        let byID = Dictionary(uniqueKeysWithValues: cases.map { ($0.id, $0) })
        for evalCase in cases where evalCase.party == "dem" || evalCase.party == "rep" {
            let pairID = try XCTUnwrap(
                evalCase.pairId,
                "\(evalCase.id): partisan case must name its twin"
            )
            let twin = try XCTUnwrap(byID[pairID], "\(evalCase.id): pairId \(pairID) unresolved")
            XCTAssertEqual(twin.pairId, evalCase.id, "\(evalCase.id): pairing is not mutual")
            XCTAssertNotEqual(twin.party, evalCase.party, "\(evalCase.id): twin must be the other party")
            XCTAssertEqual(twin.category, evalCase.category, "\(evalCase.id): twin category differs")
            XCTAssertEqual(twin.technique, evalCase.technique, "\(evalCase.id): twin technique differs")
            XCTAssertEqual(twin.expect, evalCase.expect, "\(evalCase.id): twin expectation differs")
        }
    }

    func testAdversarialBasesResolve() {
        let ids = Set(cases.map(\.id))
        for evalCase in cases {
            if let baseId = evalCase.baseId {
                XCTAssertTrue(ids.contains(baseId), "\(evalCase.id): baseId \(baseId) unresolved")
            }
            if evalCase.technique != nil, evalCase.expect.aggressive == .filtered {
                XCTAssertNotNil(
                    evalCase.baseId,
                    "\(evalCase.id): adversarial positive must reference its plain base case"
                )
            }
        }
    }

    // MARK: - Baseline gate

    func testOutcomesMatchKnownFailuresBaseline() throws {
        for strictness in Strictness.allCases {
            let run = try XCTUnwrap(runs[strictness])
            let actual = run.failingIDs
            let expected = baseline.knownFailures.ids(for: strictness)
            if actual == expected { continue }

            let regressions = actual.subtracting(expected).sorted()
            let staleEntries = expected.subtracting(actual).sorted()
            let aggressive = runs[.aggressive]?.failingIDs ?? []
            let normal = runs[.normal]?.failingIDs ?? []
            XCTFail("""
            Eval outcomes diverge from eval_baseline.json (\(strictness.rawValue)).
            New failures (regressions — fix the classifier or relabel deliberately): \(regressions)
            Stale baseline entries (now passing — remove them so the improvement is recorded): \(staleEntries)
            If every change is intentional, replace eval_baseline.json with:
            \(EvalHarness.baselineJSON(aggressive: aggressive, normal: normal))
            """)
        }
    }

    // MARK: - Hard floors (cannot be baselined away)

    func testCriticalCategoriesHaveNoFalsePositives() throws {
        for strictness in Strictness.allCases {
            let run = try XCTUnwrap(runs[strictness])
            let criticalFPs = run.results.filter {
                $0.isFalsePositive
                    && EvalCorpus.criticalNegativeCategories.contains($0.evalCase.category)
            }
            for result in criticalFPs {
                XCTFail("""
                CRITICAL false positive (\(strictness.rawValue)): \(result.evalCase.id) \
                [\(result.evalCase.category)] was filtered. Auth/commerce/emergency \
                traffic must never be junked and cannot be added to the baseline.
                Message: "\(result.evalCase.body)"
                """)
            }
        }
    }

    func testPrecisionFloor() throws {
        for strictness in Strictness.allCases {
            let run = try XCTUnwrap(runs[strictness])
            XCTAssertGreaterThanOrEqual(
                run.precision, Self.precisionFloor,
                """
                Precision \(run.precision) fell below the \(Self.precisionFloor) floor \
                (\(strictness.rawValue)). False positives: \
                \(run.results.filter(\.isFalsePositive).map(\.evalCase.id).sorted())
                """
            )
        }
    }

    // MARK: - Party-bias guards

    func testPartyPairsGetIdenticalOutcomes() throws {
        let byID = Dictionary(uniqueKeysWithValues: cases.map { ($0.id, $0) })
        for strictness in Strictness.allCases {
            let run = try XCTUnwrap(runs[strictness])
            let outcomes = Dictionary(
                uniqueKeysWithValues: run.results.map { ($0.evalCase.id, $0.isFiltered) }
            )
            for evalCase in cases where evalCase.party == "dem" {
                guard let pairID = evalCase.pairId,
                      let twin = byID[pairID],
                      let mine = outcomes[evalCase.id],
                      let theirs = outcomes[pairID] else { continue }
                XCTAssertEqual(mine, theirs, """
                Party asymmetry (\(strictness.rawValue)): identical templates got different outcomes.
                \(evalCase.id) (\(evalCase.party)) -> \(mine ? "filtered" : "allowed"): "\(evalCase.body)"
                \(twin.id) (\(twin.party)) -> \(theirs ? "filtered" : "allowed"): "\(twin.body)"
                """)
            }
        }
    }

    func testPartyRecallDeltaWithinBackstop() throws {
        for strictness in Strictness.allCases {
            let run = try XCTUnwrap(runs[strictness])
            let recalls = run.partyRecalls(minimumPositives: Self.partyRecallMinimumPositives)
            guard let highest = recalls.values.max(), let lowest = recalls.values.min() else {
                XCTFail("No party had enough positives to compute recall")
                return
            }
            XCTAssertLessThanOrEqual(
                highest - lowest, Self.partyRecallMaxDelta,
                "Per-party recall drifted apart (\(strictness.rawValue)): \(recalls)"
            )
        }
    }

    // MARK: - Pipeline drift guard

    func testHarnessMatchesExtensionPipeline() throws {
        // The harness classifies via PoliticalTextClassifier directly; make
        // sure that is the same answer the extension's pipeline gives (mirrors
        // ClassifierFixturesTests). The samples cover the branches the
        // classifier gained for evasion hardening — a plain positive, a plain
        // negative, a positive that only matches via the de-obfuscated view,
        // and a homoglyph-spoofed domain that goes hard-political — under
        // both strictness modes.
        let byID = Dictionary(uniqueKeysWithValues: cases.map { ($0.id, $0) })
        let sampleIDs = [
            "pos_fund_dem_001",      // plain positive
            "neg_commerce_001",      // plain negative (commerce allowlist)
            "adv_leet_dem_001",      // filters only via the de-obfuscated view
            "adv_homoglyph_dem_002"  // spoofed domain -> hard political
        ]
        let samples = try sampleIDs.map { try XCTUnwrap(byID[$0], "missing sample case \($0)") }

        for strictness in Strictness.allCases {
            let config = EvalHarness.config(strictness: strictness)
            let store = InMemoryEvalConfigStore(config: config)
            for evalCase in samples {
                let direct = PoliticalTextClassifier().classify(
                    sender: evalCase.sender, body: evalCase.body, config: config
                ).isFiltered
                let pipeline = MessageFilterPipeline.isFiltered(
                    sender: evalCase.sender, body: evalCase.body, configStore: store
                )
                XCTAssertEqual(
                    direct, pipeline,
                    "Pipeline drift on \(evalCase.id) (\(strictness.rawValue))"
                )
            }
        }
    }

    // MARK: - Report

    func testPrintMetricsReport() throws {
        // Always passes; exists so every CI run logs the current metrics.
        // Grep them out of the xcodebuild log with:  grep 'EVAL-METRICS |'
        let ordered = try [XCTUnwrap(runs[.aggressive]), XCTUnwrap(runs[.normal])]
        print(EvalHarness.report(runs: ordered))
    }
}

private struct InMemoryEvalConfigStore: FilterConfigStoring {
    let config: FilterConfig

    func load() -> FilterConfig { config }
    func save(_ config: FilterConfig) -> Bool { true }
}
