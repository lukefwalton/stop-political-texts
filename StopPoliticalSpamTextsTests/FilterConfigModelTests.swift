import XCTest
@testable import StopPoliticalSpamTexts

final class FilterConfigModelTests: XCTestCase {

    private var tempDir: URL!
    private var store: SharedConfigStore!
    private var model: FilterConfigModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FilterConfigModelTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = SharedConfigStore(fileName: "filter-config.json") { [tempDir] in tempDir }
        model = FilterConfigModel(store: store)
    }

    override func tearDownWithError() throws {
        model = nil
        store = nil
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        try super.tearDownWithError()
    }

    func testCategoryTogglePersistsToStore() {
        model.config.categoryToggles.campaignFundraising = false
        XCTAssertFalse(store.load().categoryToggles.campaignFundraising)
    }

    func testAddBlockedTermPersistsToStore() {
        model.addBlockedTerm("newsletter")
        XCTAssertEqual(store.load().customBlockedTerms, ["newsletter"])
    }

    func testReloadFromStorePicksUpExternalWrite() throws {
        model.config.strictness = .normal
        XCTAssertEqual(store.load().strictness, .normal)

        let fileURL = tempDir.appendingPathComponent("filter-config.json")
        Thread.sleep(forTimeInterval: 1.05)
        var rewritten = FilterConfig.defaults
        rewritten.strictness = .aggressive
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(rewritten).write(to: fileURL, options: .atomic)

        model.reloadFromStoreIfNeeded()
        XCTAssertEqual(model.config.strictness, .aggressive)
    }

    func testReloadDoesNotWriteBackUnchangedConfig() throws {
        model.config.strictness = .normal
        let fileURL = tempDir.appendingPathComponent("filter-config.json")
        let dataBefore = try Data(contentsOf: fileURL)

        model.reloadFromStoreIfNeeded()

        let dataAfter = try Data(contentsOf: fileURL)
        XCTAssertEqual(dataBefore, dataAfter)
    }

    func testRetryPersistClearsSaveFailed() {
        let flakyStore = FlakyConfigStore(failSaveCount: 1, underlying: store)
        let flaky = FilterConfigModel(store: flakyStore)

        flaky.config.strictness = .normal
        XCTAssertTrue(flaky.saveFailed)

        XCTAssertTrue(flaky.retryPersist())
        XCTAssertFalse(flaky.saveFailed)
        XCTAssertEqual(store.load().strictness, .normal)
    }

    func testHandleSceneBecameActiveRetriesFailedSave() {
        let flakyStore = FlakyConfigStore(failSaveCount: 1, underlying: store)
        let flaky = FilterConfigModel(store: flakyStore)

        flaky.config.strictness = .normal
        XCTAssertTrue(flaky.saveFailed)

        flaky.handleSceneBecameActive()
        XCTAssertFalse(flaky.saveFailed)
    }

    func testRejectsDuplicateTermsCaseInsensitively() {
        model.addBlockedTerm("Vote")
        model.addBlockedTerm("vote")
        XCTAssertEqual(model.config.customBlockedTerms, ["Vote"])
    }

    func testRejectsOverlongTerm() {
        let long = String(repeating: "a", count: FilterConfigLimits.maxCustomTermLength + 1)
        model.addBlockedTerm(long)
        XCTAssertTrue(model.config.customBlockedTerms.isEmpty)
    }

    func testRejectsWhenAtTermLimit() {
        for index in 0..<FilterConfigLimits.maxCustomTerms {
            model.addBlockedTerm("term\(index)")
        }
        model.addBlockedTerm("one too many")
        XCTAssertEqual(model.config.customBlockedTerms.count, FilterConfigLimits.maxCustomTerms)
    }
}

private final class FlakyConfigStore: FilterConfigStoring {
    var failSaveCount: Int
    let underlying: SharedConfigStore

    init(failSaveCount: Int, underlying: SharedConfigStore) {
        self.failSaveCount = failSaveCount
        self.underlying = underlying
    }

    func load() -> FilterConfig {
        underlying.load()
    }

    func save(_ config: FilterConfig) -> Bool {
        if failSaveCount > 0 {
            failSaveCount -= 1
            return false
        }
        return underlying.save(config)
    }
}
