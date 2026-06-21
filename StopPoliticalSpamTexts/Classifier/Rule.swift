import Foundation

/// Categories of classifier rules. Each maps to a config toggle (or is always on).
enum Category: String {
    case hardPolitical
    case politicalOrganization
    case politicalSlogan
    case electionTerms
    case ballotMeasure
    case fundraising
    case mobilization
    case smsMechanics
    case campaignSurveys

    /// Whether this category is active given the user's toggles.
    /// `hardPolitical` and `smsMechanics` are always evaluated when enabled.
    func isEnabled(in toggles: CategoryToggles) -> Bool {
        switch self {
        case .hardPolitical, .smsMechanics:
            return true
        case .politicalOrganization, .politicalSlogan:
            return toggles.pacPartyCommittee
        case .electionTerms, .fundraising:
            return toggles.campaignFundraising
        case .ballotMeasure:
            return toggles.ballotMeasures
        case .mobilization:
            return toggles.volunteerRallyPetition
        case .campaignSurveys:
            return toggles.campaignSurveys
        }
    }
}

/// A weighted bundle of terms. A rule contributes `weight` once if any of its
/// terms match (boundary-aware), regardless of how many terms hit.
struct Rule {
    let id: String
    /// Human-readable name shown in `TestMessageView`'s matched-rules list.
    /// Lives on the rule so a new rule can't slip into the UI as a raw id.
    let displayName: String
    let terms: [String]
    let weight: Int
    let category: Category
    /// Pairing-required rules (ballot measures) only score when another
    /// political/election/fundraising/mechanics signal is also present.
    let requiresPairing: Bool

    init(id: String, displayName: String, terms: [String], weight: Int,
         category: Category, requiresPairing: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.terms = terms
        self.weight = weight
        self.category = category
        self.requiresPairing = requiresPairing
    }

    func matches(_ normalizedText: String) -> Bool {
        terms.contains { TermMatcher.matches(term: $0, in: normalizedText) }
    }
}

/// Boundary-aware term matching for built-in rules and the allowlist.
///
/// A "letter boundary" is used instead of `\b` so that digit-suffixed campaign
/// codes match (e.g. `maga` in `MAGA2026`) while substrings inside real words
/// do not (`maga` in `magazine`, `pac` in `package`, `prop` in `proper`).
/// Multi-word phrases match as a contiguous sequence with flexible
/// whitespace/punctuation between tokens.
enum TermMatcher {
    private static var cache: [String: NSRegularExpression] = [:]
    /// Insertion order for FIFO eviction. Built-in rules + allowlists carry roughly
    /// 200 unique terms; the cap is sized to cover those plus a buffer for
    /// user-supplied custom terms without growing unboundedly across the extension's
    /// lifetime.
    private static var insertionOrder: [String] = []
    private static let cacheLimit = 256
    private static let lock = NSLock()

    static func matches(term: String, in normalizedText: String) -> Bool {
        guard !normalizedText.isEmpty else { return false }
        guard let regex = regex(for: term) else { return false }
        let range = NSRange(normalizedText.startIndex..., in: normalizedText)
        return regex.firstMatch(in: normalizedText, options: [], range: range) != nil
    }

    private static func regex(for term: String) -> NSRegularExpression? {
        let key = term.lowercased()

        // Fast path: a cache hit returns under the lock without compiling anything.
        lock.lock()
        if let cached = cache[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // Slow path: build the pattern and compile NSRegularExpression *outside* the
        // lock, so a slow compile doesn't serialize unrelated classify() calls.
        let tokens = key
            .split(whereSeparator: { $0 == " " })
            .map { NSRegularExpression.escapedPattern(for: String($0)) }
        guard !tokens.isEmpty else { return nil }

        // Letters may not directly abut the term on either side; digits and
        // punctuation may. Tokens of a phrase are separated by one or more
        // whitespace/punctuation characters.
        let body = tokens.joined(separator: "[\\s\\p{Punct}]+")
        let pattern = "(?<![a-z])" + body + "(?![a-z])"
        let compiled = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        // Double-checked insert: a concurrent caller may have raced us to compile the
        // same term — drop our copy and return theirs so cache identity is stable.
        lock.lock()
        defer { lock.unlock() }
        if let raced = cache[key] { return raced }
        cache[key] = compiled
        insertionOrder.append(key)
        if insertionOrder.count > cacheLimit {
            let drop = insertionOrder.removeFirst()
            cache.removeValue(forKey: drop)
        }
        return compiled
    }

    /// Test seam — lets the matcher tests assert the FIFO cap without exposing the
    /// cache itself.
    static var cacheCountForTesting: Int {
        lock.lock(); defer { lock.unlock() }
        return cache.count
    }

    /// Test seam — lets a FIFO test assert *which* term was evicted, not just that
    /// the cap held. Without this, a future swap to LRU/random would still pass a
    /// count-only assertion.
    static func cacheContainsForTesting(term: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return cache[term.lowercased()] != nil
    }

    /// Test seam — reset between tests so cache state doesn't leak across test cases.
    static func resetCacheForTesting() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAll()
        insertionOrder.removeAll()
    }
}
