import Foundation

/// Bounds on user-supplied custom terms. Keeps the App Group JSON and the
/// extension's regex cache from growing without limit.
enum FilterConfigLimits {
    static let maxCustomTerms = 64
    static let maxCustomTermLength = 80
}

/// How aggressively the classifier filters. Thresholds live in the classifier.
enum Strictness: String, Codable, CaseIterable {
    case normal
    case aggressive
}

/// Where filtered messages are routed. v0 is locked to `.junk`.
enum Destination: String, Codable {
    case junk
}

/// User-facing category switches. Each maps to one or more classifier rules.
/// Hard-political platforms (ActBlue, WinRed, etc.) and SMS mechanics are NOT
/// represented here. They are always evaluated when the filter is enabled.
struct CategoryToggles: Codable, Equatable {
    var campaignFundraising: Bool
    var ballotMeasures: Bool
    var campaignSurveys: Bool
    var volunteerRallyPetition: Bool
    var pacPartyCommittee: Bool

    static let allOn = CategoryToggles(
        campaignFundraising: true,
        ballotMeasures: true,
        campaignSurveys: true,
        volunteerRallyPetition: true,
        pacPartyCommittee: true
    )
}

/// The user's filtering preferences, shared between the app and the extension.
/// Persisted as JSON in the App Group container. Never holds message content.
struct FilterConfig: Codable, Equatable {
    /// Schema version. Bump when fields are added/removed; see `ConfigMigration`.
    static let currentVersion = 1

    var version: Int
    var enabled: Bool
    var destination: Destination
    var strictness: Strictness
    var categoryToggles: CategoryToggles
    var customBlockedTerms: [String]
    var customAllowedTerms: [String]
    var updatedAt: Date

    /// Safe defaults used when no config exists or a stored config is corrupt.
    /// Fail-safe means "keep filtering on", never silently disabled.
    static var defaults: FilterConfig {
        FilterConfig(
            version: currentVersion,
            enabled: true,
            destination: .junk,
            strictness: .aggressive,
            categoryToggles: .allOn,
            customBlockedTerms: [],
            customAllowedTerms: [],
            updatedAt: Date()
        )
    }
}
