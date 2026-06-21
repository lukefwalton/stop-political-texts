import XCTest
@testable import StopPoliticalSpamTexts

/// Exercises persistence + the in-process mtime cache that keeps the extension
/// off the disk on every incoming message.
final class SharedConfigStoreTests: XCTestCase {

    private var tempDir: URL!
    private var store: SharedConfigStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SharedConfigStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = SharedConfigStore(fileName: "filter-config.json") { [tempDir] in tempDir }
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        store = nil
        try super.tearDownWithError()
    }

    func testLoadReturnsDefaultsWhenNothingStored() {
        let config = store.load()
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.strictness, .aggressive)
    }

    func testFreshInstallCachesDefaultsBeforeAnySave() throws {
        // Fresh-install scenario: the extension can receive messages before
        // the user ever opens the app, i.e. before `filter-config.json`
        // exists. Repeated loads in that state must hit the in-process cache
        // instead of re-stating + re-reading the missing file.
        let fileURL = tempDir.appendingPathComponent("filter-config.json")
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))

        let first = store.load()
        XCTAssertEqual(first.strictness, .aggressive)

        // Subsequent loads return the same defaults from cache, even though
        // mtime is nil on both sides — `cachePopulated` is what gates the
        // fast path, not the date being non-nil.
        XCTAssertEqual(store.load(), first)
        XCTAssertEqual(store.load(), first)

        // When the app finally writes the file, the next load picks it up.
        var saved = FilterConfig.defaults
        saved.strictness = .normal
        Thread.sleep(forTimeInterval: 1.05)
        XCTAssertTrue(store.save(saved))
        XCTAssertEqual(store.load().strictness, .normal)
    }

    func testRoundTrip() {
        var config = FilterConfig.defaults
        config.strictness = .normal
        config.customBlockedTerms = ["newsletter"]
        XCTAssertTrue(store.save(config))

        let loaded = store.load()
        XCTAssertEqual(loaded.strictness, .normal)
        XCTAssertEqual(loaded.customBlockedTerms, ["newsletter"])
    }

    func testSaveInvalidatesCache() throws {
        var first = FilterConfig.defaults
        first.strictness = .normal
        XCTAssertTrue(store.save(first))
        XCTAssertEqual(store.load().strictness, .normal)

        // Same store instance, second write: cache must refresh, not return stale.
        var second = FilterConfig.defaults
        second.strictness = .aggressive
        // Ensure the file's mtime resolution can distinguish the two writes
        // on filesystems that round to whole seconds (HFS+ on older builds).
        Thread.sleep(forTimeInterval: 1.05)
        XCTAssertTrue(store.save(second))

        XCTAssertEqual(store.load().strictness, .aggressive)
    }

    func testExternalRewriteIsPickedUpOnNextLoad() throws {
        var config = FilterConfig.defaults
        config.strictness = .normal
        XCTAssertTrue(store.save(config))
        XCTAssertEqual(store.load().strictness, .normal)

        // Simulate the *app* writing while the extension holds a cached copy.
        let fileURL = tempDir.appendingPathComponent("filter-config.json")
        Thread.sleep(forTimeInterval: 1.05)
        var rewritten = FilterConfig.defaults
        rewritten.strictness = .aggressive
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(rewritten)
        try data.write(to: fileURL, options: .atomic)

        // mtime moved → cache is invalidated → fresh value is returned.
        XCTAssertEqual(store.load().strictness, .aggressive)
    }

    func testRepeatedLoadIsSafeAndIdempotent() {
        var config = FilterConfig.defaults
        config.customBlockedTerms = ["alpha", "beta"]
        XCTAssertTrue(store.save(config))

        let first = store.load()
        let second = store.load()
        let third = store.load()
        XCTAssertEqual(first.customBlockedTerms, ["alpha", "beta"])
        XCTAssertEqual(second.customBlockedTerms, first.customBlockedTerms)
        XCTAssertEqual(third.customBlockedTerms, first.customBlockedTerms)
    }

    func testCorruptDataFallsBackToDefaults() throws {
        let fileURL = tempDir.appendingPathComponent("filter-config.json")
        try Data("not json".utf8).write(to: fileURL, options: .atomic)
        let config = store.load()
        XCTAssertTrue(config.enabled, "Never fail-open: corrupt data must not disable filtering")
        XCTAssertEqual(config.version, FilterConfig.currentVersion)
    }

    /// Drives the seqlock retry path: the injected mtime reader returns a
    /// different value on the pre-read and post-read stat the first time
    /// through, then stabilises. `load()` must retry instead of caching the
    /// inconsistent snapshot.
    func testConcurrentWriteDuringReadIsRetriedAndNotCached() throws {
        // Seed an on-disk file with a known config so the read returns data.
        var saved = FilterConfig.defaults
        saved.strictness = .normal
        XCTAssertTrue(store.save(saved))

        // Build a second store backed by the same file with an injected
        // mtime reader that flips its answer the first time it's called
        // twice in a row — i.e. simulates a write landing between the
        // pre-read and post-read stats.
        let stale = Date(timeIntervalSince1970: 1_000_000)
        let fresh = Date(timeIntervalSince1970: 1_000_010)
        var callCount = 0
        let racing = SharedConfigStore(
            fileName: "filter-config.json",
            containerURLProvider: { [tempDir] in tempDir },
            mtimeReader: { _ in
                callCount += 1
                // Pre-read on first load returns stale, post-read returns
                // fresh -> miss; second loop both return fresh -> hit.
                switch callCount {
                case 1: return stale
                case 2: return fresh
                default: return fresh
                }
            }
        )

        let loaded = racing.load()
        XCTAssertEqual(loaded.strictness, .normal, "Mid-read write must not break the value returned")
        // 4 calls = miss-retry path: pre1, post1 (mismatch), pre2, post2 (match)
        XCTAssertEqual(callCount, 4, "Mismatch must trigger one retry before caching")

        // A subsequent load with the stabilised mtime hits the cache: no
        // further mtime calls beyond the fast-path stat.
        let cached = racing.load()
        XCTAssertEqual(cached.strictness, .normal)
        XCTAssertEqual(callCount, 5, "Second load must take the cache fast path (one stat)")
    }

    /// If a writer keeps bumping mtime under us the retries exhaust. The store
    /// must still return a usable value, but must NOT cache it — otherwise the
    /// cache could be poisoned with a torn snapshot.
    ///
    /// The "without caching" half is the tricky one to pin down. We make the
    /// mtimeReader exhaust retries on the first load, then *stabilise* it on a
    /// known value. If `load()` wrongly populated the cache during exhaustion
    /// (under whichever mtime came last), the second call would hit that cache
    /// and serve the first read's data. By swapping the file's *contents*
    /// between the two loads we make that surface as a wrong return value: a
    /// correct fix re-reads disk and returns the new payload.
    func testRetriesExhaustedReturnsBestEffortWithoutCaching() throws {
        // Save initial "normal" config.
        var saved = FilterConfig.defaults
        saved.strictness = .normal
        XCTAssertTrue(store.save(saved))

        let stableMtime = Date(timeIntervalSince1970: 9_000_000)
        var monotonic: TimeInterval = 1_000_000
        var stabilised = false

        let racing = SharedConfigStore(
            fileName: "filter-config.json",
            containerURLProvider: { [tempDir] in tempDir },
            mtimeReader: { _ in
                if stabilised { return stableMtime }
                monotonic += 1
                return Date(timeIntervalSince1970: monotonic)
            }
        )

        // First load: every mtime is unique -> retries exhaust.
        let first = racing.load()
        XCTAssertEqual(first.strictness, .normal)

        // Swap the on-disk payload while the mtimeReader stabilises.
        var rewritten = FilterConfig.defaults
        rewritten.strictness = .aggressive
        let fileURL = tempDir.appendingPathComponent("filter-config.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(rewritten).write(to: fileURL, options: .atomic)
        stabilised = true

        // Second load: if exhaustion had wrongly populated the cache, the
        // stable mtime would match the poisoned entry and we'd see the OLD
        // payload ("normal"). With the fix it falls through to a fresh read
        // and returns the new payload.
        let second = racing.load()
        XCTAssertEqual(second.strictness, .aggressive,
                       "Retries-exhausted path must not populate the cache")
    }

    func testExternalDeletionAfterValidLoadFallsBackToDefaults() throws {
        // A valid file is loaded and cached, then deleted out from under us
        // (e.g. user clears app data, or an OS migration drops the App Group
        // container). The next load() must notice via the mtime change and
        // fall back to defaults instead of returning the stale cached config.
        var saved = FilterConfig.defaults
        saved.strictness = .normal
        XCTAssertTrue(store.save(saved))
        XCTAssertEqual(store.load().strictness, .normal)

        let fileURL = tempDir.appendingPathComponent("filter-config.json")
        try FileManager.default.removeItem(at: fileURL)

        let afterDelete = store.load()
        XCTAssertEqual(afterDelete.strictness, .aggressive, "Must fall back to defaults, not stale cache")
        XCTAssertTrue(afterDelete.enabled)
    }
}
