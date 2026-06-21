import XCTest
@testable import StopPoliticalSpamTexts

final class SenderAnalyzerTests: XCTestCase {

    func testShortCodeBoost() {
        XCTAssertEqual(SenderAnalyzer.analyze("12345").boost, 2)
        XCTAssertEqual(SenderAnalyzer.analyze("123456").boost, 2)
    }

    func test10DLCBoost() {
        XCTAssertEqual(SenderAnalyzer.analyze("4155551234").boost, 1)
        XCTAssertEqual(SenderAnalyzer.analyze("+14155551234").boost, 1)
    }

    func testNonNumericSenderNoBoost() {
        XCTAssertEqual(SenderAnalyzer.analyze("VERIFY").boost, 0)
        XCTAssertEqual(SenderAnalyzer.analyze(nil).boost, 0)
    }

    func testFormattedNumberCountsDigits() {
        XCTAssertEqual(SenderAnalyzer.analyze("(415) 555-1234").boost, 1)
    }
}
