import XCTest
import SwiftUI
@testable import LFWDesignSystem

final class LFWThemeAndFontTests: XCTestCase {

    // MARK: Variable-font axis tags

    func test_axisTag_packsBigEndian() {
        // 'wght' == 0x77676874. Verified against Core Text's own identifiers.
        XCTAssertEqual(LFWVariableFont.tag("wght"), 0x77676874)
        XCTAssertEqual(LFWVariableFont.tag("opsz"), 0x6F70737A)
        XCTAssertEqual(LFWVariableFont.tag("SOFT"), 0x534F4654)
        XCTAssertEqual(LFWVariableFont.weight, 0x77676874)
    }

    func test_axisTag_roundTripsThroughCode() {
        for code in ["wght", "opsz", "SOFT", "WONK", "CASL", "slnt"] {
            XCTAssertEqual(LFWVariableFont.code(from: LFWVariableFont.tag(code)), code)
        }
    }

    // MARK: Theme config

    func test_themeConfig_defaultIsFraunchesDeepSea() {
        XCTAssertEqual(LFWThemeConfig.default.typeface, .fraunces)
        XCTAssertEqual(LFWThemeConfig.default.palette, .deepSea)
        XCTAssertEqual(LFWThemeConfig.default.accentHueShift, 0)
    }

    func test_themeConfig_codableRoundTrip() throws {
        let original = LFWThemeConfig(typeface: .recursive, palette: .sepia, accentHueShift: 40)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LFWThemeConfig.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_allTypefacesAndPalettesEnumerated() {
        XCTAssertEqual(LFWTypeface.allCases.count, 7)
        XCTAssertEqual(LFWTypeface.allCases.map(\.bundledFileName).count, 7)
        XCTAssertEqual(LFWPalette.allCases.count, 5)
        // Every palette resolves to a colors struct without trapping.
        for palette in LFWPalette.allCases {
            _ = palette.colors
        }
    }

    func test_paletteDarkness_isCorrect() {
        XCTAssertTrue(LFWPalette.deepSea.isDark)
        XCTAssertFalse(LFWPalette.paper.isDark)
        XCTAssertFalse(LFWPalette.sepia.isDark)
    }

    func test_typefaceFallbackDesign_matchesKind() {
        XCTAssertEqual(LFWTypeface.fraunces.kind, .serif)
        XCTAssertEqual(LFWTypeface.inter.kind, .sans)
        XCTAssertEqual(LFWTypeface.fraunces.fallbackDesign, .serif)
    }
}
