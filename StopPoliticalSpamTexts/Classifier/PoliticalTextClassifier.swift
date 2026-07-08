import Foundation

enum FilterAction: Equatable {
    case allow
    case filter
}

enum Confidence: String, Equatable {
    case low
    case medium
    case high
}

/// The result of classifying one message. `internalScore` is unbounded and for
/// debugging only. Surface `confidence` to users, never the raw score.
struct ClassificationResult: Equatable {
    let action: FilterAction
    let destination: Destination?
    let confidence: Confidence
    let internalScore: Int
    let matchedRules: [String]
    let reason: String?

    var isFiltered: Bool { action == .filter }
}

/// Local, on-device classifier. Pure function of (sender, body, config).
/// No network, no persistence, no logging of message content.
///
/// Precedence (each stage runs in order; earlier stages can short-circuit):
///   1. `precheck`            — disabled / empty body / critical allowlist → allow.
///                              Also computes hard-political signal that later
///                              stages and `decide` depend on.
///   2. `scoreEnabledRules`   — sum rule weights (non-pairing first, then
///                              pairing-required only when other context exists).
///   3. `applyShortenerBoost` — +3 if shortener with strong fundraising/election
///                              context, +2 with general political context.
///   4. `applySenderBoost`    — sender shape (+1 / +2) only when political
///                              context already exists.
///   5. `applyCustomTerms`    — user blocked terms (+4 each) then user allowed
///                              terms (-4 each, floor 0). Allowed terms skipped
///                              when hard-political.
///   6. `decide`              — hard-political → filter (high, floor 8);
///                              otherwise threshold check (aggressive 4 / normal
///                              6) gated by "SMS mechanics never filter alone".
struct PoliticalTextClassifier {

    /// Every score weight, boost, threshold, and confidence band the classifier
    /// applies, in one place. Built-in rule weights live on the rules; these are
    /// the remaining tuning knobs that were previously inline literals. Keeping
    /// them here makes the scoring auditable and tunable without reading the body.
    private enum Scoring {
        /// Score floor recorded for a hard-political hit (also forces high confidence).
        static let hardPoliticalFloor = 8
        /// Shortened-link boost when a strong fundraising/election signal is present.
        static let shortenerStrongBoost = 3
        /// Shortened-link boost when only general political context is present.
        static let shortenerPoliticalBoost = 2
        /// Each custom blocked term adds this; each custom allowed term subtracts it.
        static let customTermWeight = 4
        /// Filter threshold in aggressive mode.
        static let aggressiveThreshold = 4
        /// Filter threshold in normal mode.
        static let normalThreshold = 6
        /// Confidence bands: score < medium → low; < high → medium; otherwise high.
        static let mediumConfidenceFloor = 4
        static let highConfidenceFloor = 8
    }

    /// Rule IDs that count as genuine political signal (everything except SMS
    /// mechanics). Computed once and reused: it gates the sender boost and the
    /// "SMS mechanics never filter alone" rule, both checked on the per-message
    /// hot path the extension runs for every incoming text.
    private static let politicalContextRuleIDs: Set<String> = Set(
        RuleSet.rules
            .filter { $0.category != .smsMechanics }
            .map { $0.id }
    )

    /// Immutable inputs that the scoring + decide stages read but never mutate.
    /// `precheck` produces this once; later stages take it as a `let`.
    /// `views` carries the canonical normalized text plus the de-obfuscated
    /// matching view (nil for clean messages); see `MatchableText`.
    private struct ClassifyContext {
        let views: MatchableText
        let extracted: ExtractedURLs
        let senderShape: SenderShape
        let hardPolitical: Bool
        let config: FilterConfig
    }

    /// The accumulator that scoring stages thread through. Each stage takes a
    /// `ScoringState` and returns a new one — no stage mutates state owned by
    /// another stage.
    private struct ScoringState: Equatable {
        var score: Int = 0
        var matches: [String] = []
        var customBlockMatched: Bool = false
        /// True when some match only landed via the de-obfuscated view —
        /// surfaced as a synthetic "deobfuscated" entry in `matchedRules`.
        var usedDeobfuscation: Bool = false
    }

    /// `precheck` either short-circuits with a final result, or hands the
    /// downstream stages an immutable context to score against.
    private enum PrecheckOutcome {
        case shortCircuit(ClassificationResult)
        case proceed(ClassifyContext)
    }

    func classify(sender: String?, body: String?, config: FilterConfig) -> ClassificationResult {
        switch precheck(sender: sender, body: body, config: config) {
        case .shortCircuit(let result):
            return result
        case .proceed(let context):
            var state = ScoringState()
            state = scoreEnabledRules(context: context, state: state)
            state = applyShortenerBoost(context: context, state: state)
            state = applySenderBoost(context: context, state: state)
            state = applyCustomTerms(context: context, state: state)
            return decide(context: context, state: state)
        }
    }

    // MARK: - Stages

    private func precheck(sender: String?, body: String?, config: FilterConfig) -> PrecheckOutcome {
        // 1. Disabled → allow.
        guard config.enabled else {
            return .shortCircuit(.allow(reason: "disabled"))
        }

        // 2. Empty body → allow.
        guard let rawBody = body?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawBody.isEmpty else {
            return .shortCircuit(.allow(reason: "empty_body"))
        }

        // 3. Normalize, then build the de-obfuscated matching view.
        let text = Normalizer.normalize(rawBody)
        let views = Deobfuscator.matchable(text)

        // 4. Extract URLs / domains (in-memory only). Canonical view only —
        // de-obfuscation is lossy and must never rewrite hosts.
        let extracted = URLExtractor.extract(from: text)

        // 5. Sender shape.
        let senderShape = SenderAnalyzer.analyze(sender)

        // 6. Hard political detection (both views: obfuscating "actblue" is
        // itself spam intent, so a de-obfuscated hit filters at full strength).
        let hardPolitical = matchesHardPolitical(views: views, urls: extracted)

        // 7. Critical allowlist exits early unless hard political. Canonical
        // view only — the auth-code regex must see the original digits.
        if !hardPolitical, RuleSet.matchesCriticalAllowlist(text) {
            return .shortCircuit(.allow(reason: "critical_allowlist"))
        }

        return .proceed(ClassifyContext(
            views: views,
            extracted: extracted,
            senderShape: senderShape,
            hardPolitical: hardPolitical,
            config: config
        ))
    }

    private func scoreEnabledRules(context: ClassifyContext, state: ScoringState) -> ScoringState {
        // 8. Score enabled rules (non-pairing first, then pairing-required).
        var state = state
        let enabled = RuleSet.enabledRules(context.config.categoryToggles)

        for rule in enabled where !rule.requiresPairing {
            if rule.matches(context.views) {
                state.score += rule.weight
                state.matches.append(rule.id)
                if !rule.matches(context.views.text) { state.usedDeobfuscation = true }
            }
        }

        if hasPairingContext(state.matches) {
            for rule in enabled where rule.requiresPairing {
                if rule.matches(context.views) {
                    state.score += rule.weight
                    state.matches.append(rule.id)
                    if !rule.matches(context.views.text) { state.usedDeobfuscation = true }
                }
            }
        }
        return state
    }

    private func applyShortenerBoost(context: ClassifyContext, state: ScoringState) -> ScoringState {
        // 8b. Shortened-link boost (no network expansion), only with context.
        var state = state
        if context.extracted.containsShortener() {
            if matched(state.matches, anyOf: ["fundraising", "electionTerms"]) {
                state.score += Scoring.shortenerStrongBoost
                state.matches.append("url_shortener_strong")
            } else if hasPoliticalContext(state.matches, hardPolitical: context.hardPolitical) {
                state.score += Scoring.shortenerPoliticalBoost
                state.matches.append("url_shortener_political")
            }
        }
        return state
    }

    private func applySenderBoost(context: ClassifyContext, state: ScoringState) -> ScoringState {
        // 9. Sender boost, only when real political context exists.
        var state = state
        if context.senderShape.boost > 0,
           hasPoliticalContext(state.matches, hardPolitical: context.hardPolitical),
           let senderRule = context.senderShape.ruleId {
            state.score += context.senderShape.boost
            state.matches.append(senderRule)
        }
        return state
    }

    private func applyCustomTerms(context: ClassifyContext, state: ScoringState) -> ScoringState {
        var state = state

        // 10. Custom blocked terms (+4 each). Boundary-aware so a user blocking
        // "vote" does not also block "devote" / "pivotal". Both views, so a
        // user's blocked term can't be dodged with the same obfuscation
        // tricks the built-in rules are hardened against.
        for term in context.config.customBlockedTerms {
            let needle = Normalizer.normalize(term)
            guard !needle.isEmpty else { continue }
            if TermMatcher.matches(term: needle, in: context.views) {
                state.score += Scoring.customTermWeight
                state.matches.append("custom_block:\(term)")
                state.customBlockMatched = true
                if !TermMatcher.matches(term: needle, in: context.views.text) {
                    state.usedDeobfuscation = true
                }
            }
        }

        // 11. Custom allowed terms (-4 each, floor 0, no override on hard political).
        // Boundary-aware for the same reason as blocked terms.
        if !context.hardPolitical {
            for term in context.config.customAllowedTerms {
                let needle = Normalizer.normalize(term)
                guard !needle.isEmpty else { continue }
                if TermMatcher.matches(term: needle, in: context.views) {
                    state.score = max(0, state.score - Scoring.customTermWeight)
                    state.matches.append("custom_allow:\(term)")
                }
            }
        }
        return state
    }

    private func decide(context: ClassifyContext, state: ScoringState) -> ClassificationResult {
        var state = state
        if state.usedDeobfuscation {
            state.matches.append("deobfuscated")
        }

        // 12. Hard political → filter, high confidence, score floor 8.
        if context.hardPolitical {
            return ClassificationResult(
                action: .filter,
                destination: .junk,
                confidence: .high,
                internalScore: max(state.score, Scoring.hardPoliticalFloor),
                matchedRules: state.matches + ["hard_political"],
                reason: "hard_political"
            )
        }

        // SMS mechanics never filter alone: require a real political signal or
        // a custom block before a non-hard message can be filtered.
        let canFilter = hasPoliticalContext(state.matches, hardPolitical: false) || state.customBlockMatched

        // 13–14. Threshold check.
        let threshold = context.config.strictness == .aggressive ? Scoring.aggressiveThreshold : Scoring.normalThreshold
        if canFilter, state.score >= threshold {
            return ClassificationResult(
                action: .filter,
                destination: .junk,
                confidence: Self.confidence(for: state.score),
                internalScore: state.score,
                matchedRules: state.matches,
                reason: "threshold"
            )
        }

        // 15. Allow.
        return ClassificationResult(
            action: .allow,
            destination: nil,
            confidence: Self.confidence(for: state.score),
            internalScore: state.score,
            matchedRules: state.matches,
            reason: "below_threshold"
        )
    }

    // MARK: - Helpers

    private func matchesHardPolitical(views: MatchableText, urls: ExtractedURLs) -> Bool {
        if urls.matchesPoliticalDomain() { return true }
        if RuleSet.hardPoliticalTerms.contains(where: { TermMatcher.matches(term: $0, in: views) }) {
            return true
        }
        // stop2end paired with fundraising/political context is also hard.
        if TermMatcher.matches(term: "stop2end", in: views),
           RuleSet.rules.contains(where: { rule in
               (rule.category == .fundraising || rule.category == .politicalOrganization)
               && rule.matches(views)
           }) {
            return true
        }
        return false
    }

    /// Any non-ballot signal is enough to "pair" a ballot-measure rule.
    private func hasPairingContext(_ matches: [String]) -> Bool {
        let ballot: Set<String> = ["ballotMeasureNoun", "ballotMeasureAction"]
        return matches.contains { !ballot.contains($0) }
    }

    /// A genuine political signal (excludes SMS mechanics). Gates sender boost
    /// and the "never filter alone" rule.
    private func hasPoliticalContext(_ matches: [String], hardPolitical: Bool) -> Bool {
        if hardPolitical { return true }
        return matches.contains { Self.politicalContextRuleIDs.contains($0) }
    }

    private func matched(_ matches: [String], anyOf ids: [String]) -> Bool {
        let set = Set(ids)
        return matches.contains { set.contains($0) }
    }

    static func confidence(for score: Int) -> Confidence {
        switch score {
        case ..<Scoring.mediumConfidenceFloor: return .low
        case ..<Scoring.highConfidenceFloor: return .medium
        default: return .high
        }
    }
}

private extension ClassificationResult {
    static func allow(reason: String) -> ClassificationResult {
        ClassificationResult(
            action: .allow,
            destination: nil,
            confidence: .low,
            internalScore: 0,
            matchedRules: [],
            reason: reason
        )
    }
}
