import XCTest
import SwiftUI
@testable import LFWDesignSystem

final class LFWColorsTests: XCTestCase {
    func test_lfwHex_decodesAllChannels() {
        // Channels exercised independently so a wrong shift/mask in the
        // initializer can't pass by symmetry (e.g. R/B swap would still pass
        // a grayscale-only test).
        XCTAssertEqual(describeRGB(Color(lfwHex: 0xFF0000)), "1.000,0.000,0.000")
        XCTAssertEqual(describeRGB(Color(lfwHex: 0x00FF00)), "0.000,1.000,0.000")
        XCTAssertEqual(describeRGB(Color(lfwHex: 0x0000FF)), "0.000,0.000,1.000")
        XCTAssertEqual(describeRGB(Color(lfwHex: 0x1D75BC)), "0.114,0.459,0.737")
    }

    func test_palette_constantsAreStable() {
        // Lock in the brand colors so a typo can't silently change them.
        // (One sample per role — enough to catch a paste mistake without
        // turning the suite into a snapshot of every hex literal.)
        // Green leads the brand; `ocean` is now the ukiyo-e Prussian blue,
        // not the old generic web blue.
        XCTAssertEqual(describeRGB(LFWColors.forest),    "0.122,0.200,0.169")
        XCTAssertEqual(describeRGB(LFWColors.verdigris), "0.243,0.557,0.431")
        XCTAssertEqual(describeRGB(LFWColors.ocean),     "0.122,0.369,0.549")
        XCTAssertEqual(describeRGB(LFWColors.ukiyoBlue), "0.141,0.314,0.439")
        XCTAssertEqual(describeRGB(LFWColors.mist),      "0.498,0.659,0.714")
        XCTAssertEqual(describeRGB(LFWColors.gold),      "0.973,0.710,0.000") // yamabuki 山吹
        XCTAssertEqual(describeRGB(LFWColors.deepSea),   "0.000,0.165,0.255")
        XCTAssertEqual(describeRGB(LFWColors.paper),     "0.937,0.976,0.996")
    }

    func test_tint_isVerdigris() {
        // The app-wide tint is the semantic alias most consumers inherit; lock it
        // to the green so a future edit can't silently flip the brand back to blue.
        XCTAssertEqual(describeRGB(LFWColors.tint), describeRGB(LFWColors.verdigris))
    }

    func test_forestPalette_isBrandGreenAndDefault() {
        // Forest is the default theme, and its gradient bottom is a deliberate deep
        // emerald (not the brighter `verdigris` tint) so `paper` text keeps AA
        // contrast drawn directly over the gradient. Lock the load-bearing stops.
        let c = LFWPalette.forest.colors
        XCTAssertEqual(describeRGB(c.backgroundTop),    describeRGB(LFWColors.forest))
        XCTAssertEqual(describeRGB(c.backgroundBottom), "0.180,0.420,0.314") // #2E6B50
        XCTAssertEqual(describeRGB(c.accent),           describeRGB(LFWColors.gold))
    }

    private func describeRGB(_ color: Color) -> String {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%.3f,%.3f,%.3f", Double(r), Double(g), Double(b))
        #else
        return String(describing: color)
        #endif
    }
}
