import XCTest
@testable import StopPoliticalSpamTexts

final class NormalizerTests: XCTestCase {

    func testLowercases() {
        XCTAssertEqual(Normalizer.normalize("Donate NOW"), "donate now")
    }

    func testFoldsSmartQuotesAndDashes() {
        XCTAssertEqual(Normalizer.normalize("\u{201C}vote\u{201D} \u{2014} can\u{2019}t wait"), "\"vote\" - can't wait")
    }

    func testCollapsesWhitespace() {
        XCTAssertEqual(Normalizer.normalize("  vote\n\tnow   please  "), "vote now please")
    }

    func testFoldsDiacritics() {
        XCTAssertEqual(Normalizer.normalize("Café Dönate"), "cafe donate")
    }

    func testPreservesURLsAndShortcodeLanguage() {
        let input = "Reply STOP2END. Visit secure.actblue.com"
        XCTAssertEqual(Normalizer.normalize(input), "reply stop2end. visit secure.actblue.com")
    }

    func testStripsFormatCharacters() {
        // Zero-width space/joiner/non-joiner, BOM, word joiner, soft hyphen —
        // all Unicode category Cf, all invisible, all break term matching.
        XCTAssertEqual(Normalizer.normalize("Do\u{200B}nate n\u{200C}ow"), "donate now")
        XCTAssertEqual(Normalizer.normalize("mid\u{00AD}night \u{FEFF}vote\u{2060}"), "midnight vote")
    }

    func testFoldsCyrillicAndGreekHomoglyphs() {
        // Cyrillic о/е and а/с fold to their Latin lookalikes.
        XCTAssertEqual(Normalizer.normalize("D\u{043E}nate D\u{0435}mocrats"), "donate democrats")
        XCTAssertEqual(Normalizer.normalize("\u{0430}\u{0441}tblue.com"), "actblue.com")
        // Greek omicron/alpha.
        XCTAssertEqual(Normalizer.normalize("v\u{03BF}te \u{03B1}gain"), "vote again")
    }

    func testHomoglyphFoldingLeavesGenuineCyrillicHarmless() {
        // Real Cyrillic text partially folds (confusables only) but must not
        // produce Latin rule terms; unmapped letters keep tokens non-matching.
        let normalized = Normalizer.normalize("Привет! Встреча в 7 вечера.")
        XCTAssertFalse(normalized.contains("vote"))
        XCTAssertFalse(normalized.contains("donate"))
    }

    func testFoldsFullwidthCharacters() {
        XCTAssertEqual(Normalizer.normalize("ＤＯＮＡＴＥ ｎｏｗ"), "donate now")
    }
}
