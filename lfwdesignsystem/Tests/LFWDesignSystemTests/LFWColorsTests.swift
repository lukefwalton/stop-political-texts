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
        XCTAssertEqual(describeRGB(LFWColors.gold),      "1.000,0.804,0.204")
        XCTAssertEqual(describeRGB(LFWColors.deepSea),   "0.000,0.165,0.255")
        XCTAssertEqual(describeRGB(LFWColors.paper),     "0.937,0.976,0.996")
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
