import XCTest
@testable import StopPoliticalSpamTexts

final class DeobfuscatorTests: XCTestCase {

    /// Deobfuscator takes already-normalized text; go through the real
    /// normalizer so tests exercise the same pipeline the classifier runs.
    private func deob(_ input: String) -> String? {
        Deobfuscator.deobfuscate(Normalizer.normalize(input))
    }

    // MARK: - Clean text

    func testCleanTextReturnsNil() {
        XCTAssertNil(deob("Donate before midnight to help Democrats."))
        XCTAssertNil(deob("Your verification code is 123456."))
        XCTAssertNil(deob("Your order has shipped and arrives Thursday."))
    }

    func testMatchableViewsCarryNilForCleanText() {
        let views = Deobfuscator.matchable("donate now")
        XCTAssertEqual(views.text, "donate now")
        XCTAssertNil(views.deobfuscated)
    }

    // MARK: - Stuffed / spaced letters

    func testCollapsesPunctuationStuffedLetters() {
        XCTAssertEqual(deob("d.o.n.a.t.e before midnight"), "donate before midnight")
        XCTAssertEqual(deob("d-o-n-a-t-e now"), "donate now")
    }

    func testCollapsesSpacedLetters() {
        XCTAssertEqual(deob("d o n a t e now"), "donate now")
    }

    func testStuffedRunEndsBeforeOrdinaryWord() {
        // The trailing single letter of a run must not swallow the next word.
        XCTAssertEqual(deob("v o t e yes on Measure 4"), "vote yes on measure 4")
    }

    func testShortAbbreviationsSurvive() {
        // Three letters or fewer never collapse: real-world abbreviations.
        XCTAssertNil(deob("f y i the meeting moved"))
        XCTAssertNil(deob("e.g. this works"))
        XCTAssertNil(deob("V.I.P. sale ends tonight - 50% off everything."))
    }

    func testMixedSeparatorsDoNotCollapse() {
        // A run must use one identical separator throughout.
        XCTAssertNil(deob("d.o-n.a-t.e"))
    }

    // MARK: - Repeated characters

    func testCollapsesRepeatedLetterRuns() {
        XCTAssertEqual(deob("dooonate now"), "donate now")
        XCTAssertEqual(
            deob("Sooooo excited for tonight!!! See you there."),
            "so excited for tonight!!! see you there."
        )
    }

    func testDoubledLettersSurvive() {
        // English doubles are normal spelling, not obfuscation.
        XCTAssertNil(deob("the committee will need volunteers off saturday"))
    }

    func testRunCollapseIsInertForURLs() {
        // "www" collapses to "w" in this matching-only view. That is harmless
        // by design: URL extraction reads the canonical view, and no rule term
        // is "w". This test pins the behavior so a future change is deliberate.
        XCTAssertEqual(
            deob("schedule posted at www.example.com - see you saturday!!!"),
            "schedule posted at w.example.com - see you saturday!!!"
        )
    }

    // MARK: - Leetspeak

    func testFoldsInteriorLeet() {
        XCTAssertEqual(deob("d0nate before m1dnight"), "donate before midnight")
        XCTAssertEqual(deob("don@te today"), "donate today")
        XCTAssertEqual(deob("take our surv3y"), "take our survey")
    }

    func testAuthCodeDigitsAreNeverFolded() {
        // Pure digit runs contain no letters, so codes keep their digits and
        // the auth allowlist (canonical view) still sees "123456".
        XCTAssertEqual(deob("your c0de is 123456."), "your code is 123456.")
        XCTAssertNil(deob("your verification code is 123456."))
    }

    func testDigitAdjacentTokensAreUntouched() {
        // Digits flanked by digits are real digits (MAGA2026-style codes),
        // and stop2end's 2 is not in the leet map at all.
        XCTAssertNil(deob("use code maga2026. donate $500."))
        XCTAssertNil(deob("reply stop2end. donate $10."))
    }

    func testLeadingAndTrailingLeetAreUntouched() {
        // Only interior characters fold; "$5" and "don8" stay as typed.
        XCTAssertNil(deob("chip in $5 now"))
        XCTAssertNil(deob("don8 tonight"))
    }

    // MARK: - Combined techniques

    func testStuffingAndLeetComposeAcrossWords() {
        XCTAssertEqual(
            deob("D.e.m.o.c.r.a.t.s need your help. D0nate bef0re m1dnight."),
            "democrats need your help. donate before midnight."
        )
    }

    // MARK: - View matching

    func testTermMatcherFallsBackToDeobfuscatedView() {
        let views = Deobfuscator.matchable(Normalizer.normalize("D0nate before m1dnight"))
        XCTAssertNotNil(views.deobfuscated)
        XCTAssertTrue(TermMatcher.matches(term: "donate", in: views))
        XCTAssertFalse(TermMatcher.matches(term: "actblue", in: views))
    }
}
