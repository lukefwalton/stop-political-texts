import XCTest
@testable import StopPoliticalSpamTexts

final class URLExtractorTests: XCTestCase {

    private func extract(_ text: String) -> ExtractedURLs {
        URLExtractor.extract(from: Normalizer.normalize(text))
    }

    func testExtractsHostFromSchemedURL() {
        let result = extract("Donate here: https://secure.actblue.com/abc123")
        XCTAssertTrue(result.hosts.contains("secure.actblue.com"))
    }

    func testExtractsBareDomain() {
        let result = extract("Go to winred.com now")
        XCTAssertTrue(result.hosts.contains("winred.com"))
    }

    func testDetectsPoliticalDomain() {
        XCTAssertTrue(extract("see actblue.com/x").matchesPoliticalDomain())
        XCTAssertTrue(extract("see dccc.org").matchesPoliticalDomain())
    }

    func testDetectsPartyCommitteeDomains() {
        XCTAssertTrue(extract("give at dscc.org").matchesPoliticalDomain())
        XCTAssertTrue(extract("donate at nrsc.org").matchesPoliticalDomain())
    }

    func testDetectsShortener() {
        XCTAssertTrue(extract("link bit.ly/example").containsShortener())
        XCTAssertTrue(extract("link tinyurl.com/abc").containsShortener())
    }

    func testIgnoresPlainSentences() {
        let result = extract("Vote now please. Thanks.")
        XCTAssertTrue(result.hosts.isEmpty)
    }

    func testNonPoliticalDomainIsNotFlagged() {
        let result = extract("Track at ups.com/track")
        XCTAssertFalse(result.matchesPoliticalDomain())
        XCTAssertFalse(result.containsShortener())
    }
}
