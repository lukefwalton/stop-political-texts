import XCTest
@testable import StopPoliticalSpamTexts

/// Direct coverage of `TermMatcher` — the boundary-aware token matcher built-in
/// rules and the allowlist both run through. Tests live here (not embedded in
/// `PoliticalTextClassifierTests`) so the classifier tests stay focused on
/// user-visible classification decisions, while the matcher's phrase-separator
/// behavior (whitespace/mid-sentence punctuation only) and
/// `(?<![a-z])…(?![a-z])` letter-boundary rule are pinned independently of any
/// scoring/threshold change.
final class TermMatcherTests: XCTestCase {

    override func setUp() {
        super.setUp()
        TermMatcher.resetCacheForTesting()
    }

    func testTermMatchesAcrossPunctuationSeparators() {
        // The matcher treats whitespace and punctuation as interchangeable token
        // separators, so the same term should hit when wrapped in ! or () or
        // hyphenated with the next word. Pinned here so a future regex tweak
        // can't silently regress these forms.
        let bodies = [
            "Why I think you should vote! It matters.",
            "Reminder: (vote) before the deadline.",
            "Tell a friend to vote-now or else."
        ]
        for body in bodies {
            XCTAssertTrue(TermMatcher.matches(term: "vote", in: body),
                          "TermMatcher should match 'vote' in: \(body)")
        }
    }

    func testFlexiblePhraseTokensMatchAcrossMidSentencePunctuation() {
        // Hyphens, commas, parens, and colons between phrase tokens must not
        // defeat a flexible multi-word term.
        XCTAssertTrue(TermMatcher.matches(term: "chip in", in: "Chip-in $5 before midnight."))
        XCTAssertTrue(TermMatcher.matches(term: "yes on", in: "Vote yes, on Prop 12."))
        XCTAssertTrue(TermMatcher.matches(term: "chip in", in: "chip (in) $5 today"))
    }

    func testFlexiblePhraseTokensDoNotBridgeSentenceTerminalPunctuation() {
        // Even a flexible phrase must never assemble itself out of two
        // adjacent sentences. Pinned for . ! ? ; and the ellipsis.
        for body in [
            "Bring a chip. In the bag, please.",
            "What a chip! In other news, hello.",
            "Got a chip? In that case, celebrate.",
            "One more chip; in moderation, of course.",
            "Last chip… in the end it was worth it."
        ] {
            XCTAssertFalse(TermMatcher.matches(term: "chip in", in: body.lowercased()),
                           "phrase should not bridge sentences in: \(body)")
        }
    }

    func testWhitespaceOnlyPhrasesRejectAllPunctuationBetweenTokens() {
        // Strict phrases (Rule.strictPhrases) join tokens across whitespace
        // alone: "House majority" in real political copy is contiguous, so
        // any punctuation between the tokens signals unrelated prose.
        XCTAssertTrue(TermMatcher.matches(
            term: "house majority", in: "a house majority miracle tonight",
            separator: .whitespaceOnly))
        for body in [
            "open house: majority of the units are already sold.",
            "open house, majority of the units are already sold.",
            "a house (majority) of cards",
            "house-majority pricing ends friday",
            "open house. majority of the units are already sold."
        ] {
            XCTAssertFalse(TermMatcher.matches(term: "house majority", in: body,
                                               separator: .whitespaceOnly),
                           "strict phrase should not match in: \(body)")
        }
    }

    func testTermDoesNotMatchInsideAWordWithLetterBoundary() {
        // Letter boundaries: substrings inside real words must not match — the
        // contrast with the punctuation cases above is the whole point of the
        // custom boundary instead of \b.
        XCTAssertFalse(TermMatcher.matches(term: "art", in: "Democratic Party event"))
        XCTAssertFalse(TermMatcher.matches(term: "pac", in: "Open the package by noon."))
        XCTAssertFalse(TermMatcher.matches(term: "prop", in: "be proper, ok?"))
    }

    func testTermMatchesNextToDigitsButNotLetters() {
        // Digit-suffixed campaign codes (e.g. "MAGA2026") are the canonical reason
        // this matcher uses a letter boundary instead of \b. Pin the digit-OK case
        // alongside the letter-blocked case so the asymmetry is regression-tested.
        XCTAssertTrue(TermMatcher.matches(term: "maga", in: "Donate to MAGA2026 today!"))
        XCTAssertFalse(TermMatcher.matches(term: "maga", in: "Subscribe to the magazine."))
    }

    func testCacheRespectsFIFOLimit() {
        // Insert more terms than the cap and assert the cache size never exceeds it.
        // Distinct terms keep the matcher from finding cache hits, so each call
        // forces a regex compile + insert.
        TermMatcher.resetCacheForTesting()
        for i in 0..<300 {
            _ = TermMatcher.matches(term: "term\(i)", in: "irrelevant body")
        }
        XCTAssertLessThanOrEqual(TermMatcher.cacheCountForTesting, 256,
                                 "FIFO cap should keep cache from growing unbounded")
    }

    func testCacheEvictionIsFIFOSpecifically() {
        // Pin FIFO order, not just boundedness: seed an "oldest" term, re-access it
        // mid-stream (FIFO ignores the access — its position is by insertion order;
        // LRU would move it to most-recent), then overflow the cap. Under FIFO,
        // "oldest" must be evicted while the most recently inserted filler must
        // still be present. A future swap to LRU/random would fail this test.
        TermMatcher.resetCacheForTesting()
        _ = TermMatcher.matches(term: "oldest", in: "irrelevant")

        // Halfway through, re-access "oldest" — a cache hit that does not touch
        // insertionOrder under FIFO. (Under LRU this would promote it to most-recent.)
        for i in 0..<128 {
            _ = TermMatcher.matches(term: "filler\(i)", in: "irrelevant")
        }
        _ = TermMatcher.matches(term: "oldest", in: "irrelevant")
        for i in 128..<256 {
            _ = TermMatcher.matches(term: "filler\(i)", in: "irrelevant")
        }

        XCTAssertFalse(TermMatcher.cacheContainsForTesting(term: "oldest"),
                       "FIFO eviction should evict the oldest-inserted term even after a cache hit on it")
        XCTAssertTrue(TermMatcher.cacheContainsForTesting(term: "filler255"),
                      "the newest-inserted filler must still be cached after eviction")
        XCTAssertLessThanOrEqual(TermMatcher.cacheCountForTesting, 256)
    }
}
