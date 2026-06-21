import Foundation

/// Tolerant config decoding + forward migration.
///
/// Reading never throws: a missing or corrupt field falls back to the safe
/// default for that field (filtering stays enabled, so we never "fail open" into
/// an unfiltered state because of a bad optional). When the stored schema is
/// older than `FilterConfig.currentVersion`, user preferences are preserved and
/// merged onto current defaults with the version bumped.
enum ConfigMigration {

    static func migrate(from data: Data?) -> FilterConfig {
        guard let data = data,
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any] else {
            return .defaults
        }
        return migrate(from: dict)
    }

    static func migrate(from dict: [String: Any]) -> FilterConfig {
        var config = FilterConfig.defaults

        if let enabled = dict["enabled"] as? Bool {
            config.enabled = enabled
        }
        if let destination = dict["destination"] as? String,
           let parsed = Destination(rawValue: destination) {
            config.destination = parsed
        }
        if let strictness = dict["strictness"] as? String,
           let parsed = Strictness(rawValue: strictness) {
            config.strictness = parsed
        }
        if let toggles = dict["categoryToggles"] as? [String: Any] {
            config.categoryToggles = mergeToggles(toggles, onto: config.categoryToggles)
        }
        if let blocked = dict["customBlockedTerms"] as? [String] {
            config.customBlockedTerms = sanitize(blocked)
        }
        if let allowed = dict["customAllowedTerms"] as? [String] {
            config.customAllowedTerms = sanitize(allowed)
        }

        // Always normalize to the current schema version on read. Preserve the
        // stored timestamp when present so updatedAt reflects the last real
        // change rather than the moment of this read; fall back to the default
        // (now) only when it is missing or unparseable.
        config.version = FilterConfig.currentVersion
        if let updatedAt = dict["updatedAt"] as? String,
           let parsed = ISO8601DateFormatter().date(from: updatedAt) {
            config.updatedAt = parsed
        }
        return config
    }

    private static func mergeToggles(_ raw: [String: Any], onto base: CategoryToggles) -> CategoryToggles {
        var toggles = base
        if let value = raw["campaignFundraising"] as? Bool { toggles.campaignFundraising = value }
        if let value = raw["ballotMeasures"] as? Bool { toggles.ballotMeasures = value }
        if let value = raw["campaignSurveys"] as? Bool { toggles.campaignSurveys = value }
        if let value = raw["volunteerRallyPetition"] as? Bool { toggles.volunteerRallyPetition = value }
        if let value = raw["pacPartyCommittee"] as? Bool { toggles.pacPartyCommittee = value }
        return toggles
    }

    private static func sanitize(_ terms: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for term in terms {
            guard result.count < FilterConfigLimits.maxCustomTerms else { break }
            let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  trimmed.count <= FilterConfigLimits.maxCustomTermLength else { continue }
            let key = trimmed.lowercased()
            if seen.insert(key).inserted {
                result.append(trimmed)
            }
        }
        return result
    }
}
