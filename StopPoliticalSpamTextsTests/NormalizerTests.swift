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
}
