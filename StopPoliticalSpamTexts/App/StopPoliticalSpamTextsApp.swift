import SwiftUI

@main
struct StopPoliticalSpamTextsApp: App {
    @StateObject private var model = FilterConfigModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .tint(BrandColor.ocean)
                .fontDesign(.rounded)
        }
    }
}

/// Shows the first-run onboarding until it is completed once, then the app
/// proper. The flag lives in `UserDefaults` so the flow never returns.
private struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var model: FilterConfigModel

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                NavigationStack {
                    MainView()
                }
                .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                model.handleSceneBecameActive()
            }
        }
    }
}

/// Observable wrapper over `SharedConfigStore`. Edits persist to the App Group
/// immediately so the extension sees them on the next classification.
final class FilterConfigModel: ObservableObject {
    @Published var config: FilterConfig {
        didSet {
            guard !isApplyingExternalLoad else { return }
            persist()
        }
    }

    /// True when the most recent save to the App Group container failed, meaning
    /// the extension may still be using stale config. Surfaced in `MainView`.
    @Published private(set) var saveFailed = false

    private let store: FilterConfigStoring
    /// Guards `didSet` when adopting config already on disk so we do not write back.
    private var isApplyingExternalLoad = false

    init(store: FilterConfigStoring = SharedConfigStore.shared) {
        self.store = store
        self.config = store.load()
    }

    /// Called when the app becomes active. Retries a failed save first; otherwise
    /// reloads from disk so the UI reflects any external App Group changes.
    func handleSceneBecameActive() {
        if saveFailed {
            retryPersist()
            return
        }
        reloadFromStoreIfNeeded()
    }

    /// Adopts the on-disk config when it differs from the in-memory copy.
    func reloadFromStoreIfNeeded() {
        let loaded = store.load()
        guard loaded != config else { return }
        isApplyingExternalLoad = true
        config = loaded
        isApplyingExternalLoad = false
        saveFailed = false
    }

    /// Re-attempts persisting the current in-memory config after a prior failure.
    @discardableResult
    func retryPersist() -> Bool {
        saveFailed = !store.save(config)
        return !saveFailed
    }

    private func persist() {
        var toSave = config
        toSave.updatedAt = Date()
        saveFailed = !store.save(toSave)
    }

    func addBlockedTerm(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidNewTerm(trimmed, in: config.customBlockedTerms) else { return }
        config.customBlockedTerms.append(trimmed)
    }

    func addAllowedTerm(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidNewTerm(trimmed, in: config.customAllowedTerms) else { return }
        config.customAllowedTerms.append(trimmed)
    }

    func removeBlockedTerms(at offsets: IndexSet) {
        config.customBlockedTerms.remove(atOffsets: offsets)
    }

    func removeAllowedTerms(at offsets: IndexSet) {
        config.customAllowedTerms.remove(atOffsets: offsets)
    }

    private func isValidNewTerm(_ trimmed: String, in existing: [String]) -> Bool {
        guard !trimmed.isEmpty,
              trimmed.count <= FilterConfigLimits.maxCustomTermLength,
              existing.count < FilterConfigLimits.maxCustomTerms,
              !existing.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            return false
        }
        return true
    }
}
