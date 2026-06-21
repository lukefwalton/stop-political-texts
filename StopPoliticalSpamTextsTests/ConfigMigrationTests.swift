import XCTest
@testable import StopPoliticalSpamTexts

final class ConfigMigrationTests: XCTestCase {

    func testNilDataFallsBackToDefaults() {
        let config = ConfigMigration.migrate(from: nil)
        XCTAssertEqual(config, FilterConfig.defaults.withMatchingTimestamp(config))
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.strictness, .aggressive)
    }

    func testCorruptDataFallsBackToDefaults() {
        let data = Data("not json".utf8)
        let config = ConfigMigration.migrate(from: data)
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.version, FilterConfig.currentVersion)
    }

    func testPreservesUserPreferences() {
        let dict: [String: Any] = [
            "version": 0,
            "enabled": false,
            "destination": "junk",
            "strictness": "normal",
            "categoryToggles": [
                "campaignFundraising": false,
                "ballotMeasures": true,
                "campaignSurveys": false,
                "volunteerRallyPetition": true,
                "pacPartyCommittee": false
            ],
            "customBlockedTerms": ["newsletter", "newsletter"],
            "customAllowedTerms": ["book club", "Book Club", "  book club  "]
        ]
        let config = ConfigMigration.migrate(from: dict)

        XCTAssertEqual(config.version, FilterConfig.currentVersion, "version is bumped")
        XCTAssertFalse(config.enabled)
        XCTAssertEqual(config.strictness, .normal)
        XCTAssertFalse(config.categoryToggles.campaignFundraising)
        XCTAssertFalse(config.categoryToggles.pacPartyCommittee)
        XCTAssertTrue(config.categoryToggles.ballotMeasures)
        XCTAssertEqual(config.customBlockedTerms, ["newsletter"], "duplicates removed")
        // Allowed terms get the same sanitization: case-insensitive dedupe and
        // trim. A refactor that drops dedupe from customAllowedTerms used to
        // pass this test because the assertion didn't exercise the path.
        XCTAssertEqual(config.customAllowedTerms, ["book club"], "duplicates + casing + whitespace folded")
    }

    func testMissingOptionalFieldUsesDefault() {
        // A bad/missing field must not disable filtering ("never fail open").
        let dict: [String: Any] = ["strictness": "normal"]
        let config = ConfigMigration.migrate(from: dict)
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.strictness, .normal)
        XCTAssertEqual(config.categoryToggles, .allOn)
    }

    func testPreservesStoredUpdatedAt() {
        // The ISO8601 timestamp written by SharedConfigStore survives a read
        // instead of being overwritten with "now".
        let stored = "2024-01-02T03:04:05Z"
        let config = ConfigMigration.migrate(from: ["updatedAt": stored])
        XCTAssertEqual(ISO8601DateFormatter().string(from: config.updatedAt), stored)
    }

    func testUnparseableUpdatedAtFallsBackToNow() {
        let before = Date()
        let config = ConfigMigration.migrate(from: ["updatedAt": "not a date"])
        XCTAssertGreaterThanOrEqual(config.updatedAt.timeIntervalSince1970,
                                    before.timeIntervalSince1970)
    }

    func testSanitizeEnforcesCustomTermLimits() {
        let long = String(repeating: "x", count: FilterConfigLimits.maxCustomTermLength + 10)
        let tooMany = (0..<(FilterConfigLimits.maxCustomTerms + 5)).map { "term\($0)" }
        let config = ConfigMigration.migrate(from: [
            "customBlockedTerms": [long] + tooMany,
            "customAllowedTerms": tooMany + [long]
        ])

        XCTAssertTrue(config.customBlockedTerms.allSatisfy {
            $0.count <= FilterConfigLimits.maxCustomTermLength
        })
        XCTAssertTrue(config.customAllowedTerms.allSatisfy {
            $0.count <= FilterConfigLimits.maxCustomTermLength
        })
        XCTAssertLessThanOrEqual(config.customBlockedTerms.count, FilterConfigLimits.maxCustomTerms)
        XCTAssertLessThanOrEqual(config.customAllowedTerms.count, FilterConfigLimits.maxCustomTerms)
    }
}

private extension FilterConfig {
    /// Defaults with the timestamp aligned to another config, so `Equatable`
    /// comparisons ignore the always-now `updatedAt`.
    func withMatchingTimestamp(_ other: FilterConfig) -> FilterConfig {
        var copy = self
        copy.updatedAt = other.updatedAt
        return copy
    }
}
