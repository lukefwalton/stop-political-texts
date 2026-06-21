import XCTest
@testable import StopPoliticalSpamTexts

final class MessageFilterPipelineTests: XCTestCase {

    private var tempDir: URL!
    private var store: SharedConfigStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MessageFilterPipelineTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = SharedConfigStore(fileName: "filter-config.json") { [tempDir] in tempDir }
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        store = nil
        try super.tearDownWithError()
    }

    func testFiltersPoliticalMessageUsingSharedStore() {
        XCTAssertTrue(MessageFilterPipeline.isFiltered(
            sender: "12345",
            body: "ActBlue: donate before midnight to help Democrats!",
            configStore: store
        ))
    }

    func testDisabledConfigAllowsEverything() throws {
        var config = FilterConfig.defaults
        config.enabled = false
        XCTAssertTrue(store.save(config))

        XCTAssertFalse(MessageFilterPipeline.isFiltered(
            sender: nil,
            body: "ActBlue: donate before midnight!",
            configStore: store
        ))
    }

    func testOversizedBodyIsCappedWithoutCrashing() {
        let politicalHead = "ActBlue: donate before midnight to help Democrats. "
        let padding = String(repeating: "x", count: MessageFilterPipeline.maxBodyLength + 500)
        let body = politicalHead + padding

        XCTAssertTrue(MessageFilterPipeline.isFiltered(
            sender: nil,
            body: body,
            configStore: store
        ))
    }

    func testEmptyBodyIsAllowed() {
        XCTAssertFalse(MessageFilterPipeline.isFiltered(
            sender: nil,
            body: "   ",
            configStore: store
        ))
    }

    func testRespectsStrictnessFromStore() throws {
        var config = FilterConfig.defaults
        config.strictness = .normal
        XCTAssertTrue(store.save(config))

        // Aggressive-only allow case from PoliticalTextClassifierTests.
        XCTAssertFalse(MessageFilterPipeline.isFiltered(
            sender: nil,
            body: "Vote on the board proposal tomorrow.",
            configStore: store
        ))
    }
}
