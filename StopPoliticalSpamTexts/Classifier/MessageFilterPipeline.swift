import Foundation

/// Shared entry point for the message-filter extension and its unit tests.
/// Keeps body capping, config loading, and classification in one place so the
/// extension cannot drift from what the app tests.
enum MessageFilterPipeline {

    /// SMS bodies are ~1.6KB max for concatenated messages; cap well above that
    /// so a pathological input cannot make the hot-path regex work explode.
    static let maxBodyLength = 4_000

    static func classify(
        sender: String?,
        body: String?,
        configStore: FilterConfigStoring = SharedConfigStore.shared
    ) -> ClassificationResult {
        let config = configStore.load()
        let bodyForClassification = body.map { raw -> String in
            raw.count <= maxBodyLength ? raw : String(raw.prefix(maxBodyLength))
        }
        return PoliticalTextClassifier().classify(
            sender: sender,
            body: bodyForClassification,
            config: config
        )
    }

    static func isFiltered(
        sender: String?,
        body: String?,
        configStore: FilterConfigStoring = SharedConfigStore.shared
    ) -> Bool {
        classify(sender: sender, body: body, configStore: configStore).isFiltered
    }
}
