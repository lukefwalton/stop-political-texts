import Foundation

/// Persistence surface shared by the app model and tests.
protocol FilterConfigStoring {
    func load() -> FilterConfig
    @discardableResult func save(_ config: FilterConfig) -> Bool
}

/// Reads/writes `FilterConfig` as JSON in the App Group container so the app and
/// the Message Filter Extension share one source of truth. Stores preferences
/// only. Never message content, sender info, or phone numbers.
///
/// **Concurrency model.** Each process (the app, every `MessageFilterExtension`
/// instance iOS spins up) owns its own in-process `cacheLock` + cached config.
/// Cross-process coordination is provided by **atomic writes + mtime-based cache
/// invalidation**: a write from any process bumps mtime atomically; the next
/// `load()` in another process detects the mtime change via the seqlock pattern
/// and re-reads from disk. No `NSFileCoordinator` — for a preferences-only store,
/// the brief read divergence between concurrent extension processes that have
/// each cached an older mtime is **accepted and harmless** (at worst, one
/// message gets classified against the previous config until the next read).
/// Adding NSFileCoordinator would gate every read on a system-wide coordinator
/// for no user-visible win.
final class SharedConfigStore {

    static let appGroupID = "group.com.lukewalton.stoppoliticalspamtexts"
    static let shared = SharedConfigStore(appGroupID: appGroupID)

    private let containerURLProvider: () -> URL?
    private let fileName: String
    private let fileManager = FileManager.default
    /// Reads the file's modification date. Default uses `FileManager`; tests can
    /// inject a hook that returns a different value across the pre/post-read
    /// stat calls to simulate a concurrent writer landing inside the read window.
    private let mtimeReader: (URL) -> Date?

    // Cache so the extension doesn't re-decode JSON on every incoming message.
    // The mtime is the invalidation key: any write from the app (always atomic)
    // bumps it, so the next read picks up fresh config. `cachePopulated` is
    // tracked separately from `cachedModificationDate` so the "file does not
    // exist yet" path (mtime nil) is also cached — otherwise fresh installs
    // would re-stat + fall back to defaults on every incoming message until
    // the user opens the app.
    private let cacheLock = NSLock()
    private var cachedConfig: FilterConfig?
    private var cachedModificationDate: Date?
    private var cachePopulated = false

    convenience init(appGroupID: String) {
        let manager = FileManager.default
        self.init(fileName: "filter-config.json") {
            manager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        }
    }

    /// Designated initializer used by `init(appGroupID:)` and by tests that
    /// need a deterministic on-disk location instead of an App Group container.
    /// `mtimeReader` is a test seam — production callers pass the default.
    init(fileName: String,
         containerURLProvider: @escaping () -> URL?,
         mtimeReader: ((URL) -> Date?)? = nil) {
        self.fileName = fileName
        self.containerURLProvider = containerURLProvider
        let manager = FileManager.default
        self.mtimeReader = mtimeReader ?? { url in
            (try? manager.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
        }
    }

    private var fileURL: URL? {
        containerURLProvider()?.appendingPathComponent(fileName)
    }

    /// Loads config, tolerating missing/corrupt data and migrating older schemas.
    /// Always returns a usable config (defaults when nothing valid is stored).
    ///
    /// Snapshot consistency: stat mtime → read data → re-stat mtime. If both
    /// stats match, the read was atomic against any concurrent writer (the
    /// main app's `.atomic` rename) and we can cache under that mtime. If
    /// they differ, a write landed mid-read and we retry. Without the post-
    /// read stat the cache could be poisoned with new data stamped under
    /// the old mtime — then the next stat would match the cache forever.
    func load() -> FilterConfig {
        guard let fileURL = fileURL else { return .defaults }

        for _ in 0..<maxLoadRetries {
            let mtimeBefore = mtime(at: fileURL)

            cacheLock.lock()
            if cachePopulated, cachedModificationDate == mtimeBefore, let cached = cachedConfig {
                cacheLock.unlock()
                return cached
            }
            cacheLock.unlock()

            let data = try? Data(contentsOf: fileURL)
            let mtimeAfter = mtime(at: fileURL)
            guard mtimeBefore == mtimeAfter else { continue }

            let config: FilterConfig
            if let data = data {
                config = ConfigMigration.migrate(from: data)
            } else {
                config = .defaults
            }

            cacheLock.lock()
            cachedConfig = config
            cachedModificationDate = mtimeAfter
            cachePopulated = true
            cacheLock.unlock()

            return config
        }

        // Retries exhausted: a writer kept bumping mtime under us. Return a
        // best-effort snapshot without poisoning the cache.
        if let data = try? Data(contentsOf: fileURL) {
            return ConfigMigration.migrate(from: data)
        }
        return .defaults
    }

    private static let maxLoadRetries = 3
    private var maxLoadRetries: Int { Self.maxLoadRetries }

    private func mtime(at url: URL) -> Date? { mtimeReader(url) }

    /// Persists config as pretty ISO8601 JSON. Returns whether the write landed.
    @discardableResult
    func save(_ config: FilterConfig) -> Bool {
        guard let fileURL = fileURL else { return false }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(config) else { return false }
        do {
            // Until-first-unlock protection so the extension can read settings
            // when a text arrives on a locked device.
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            // Invalidate the cache so the next load() picks up the new mtime.
            cacheLock.lock()
            cachedConfig = nil
            cachedModificationDate = nil
            cachePopulated = false
            cacheLock.unlock()
            return true
        } catch {
            return false
        }
    }
}

extension SharedConfigStore: FilterConfigStoring {}
