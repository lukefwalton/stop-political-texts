import XCTest
import SwiftUI
@testable import LFWDesignSystem

/// Guards for the shared component surface added in 2.1.0. These are structural
/// (construct every public initializer; assert the semantic tokens stay distinct)
/// rather than snapshot tests — enough to catch an API break or a color collapse
/// without a rendering host.
final class LFWComponentsTests: XCTestCase {

    // success / warning / danger must never collapse to the same on-screen color.
    func test_semanticStatusColors_areDistinct() {
        let rendered = Set([
            describeRGB(LFWColors.success),
            describeRGB(LFWColors.warning),
            describeRGB(LFWColors.danger),
        ])
        XCTAssertEqual(rendered.count, 3)
    }

    // Exercises every public initializer for the 2.1.0 components so a signature
    // break fails the build here rather than only in a consuming app.
    func test_componentInitializers_compile() {
        _ = LFWEmptyState(symbol: "star", title: "Empty")
        _ = LFWEmptyState(symbol: "star", title: "Empty", message: "m",
                          eyebrow: "NOTHING HERE", accent: LFWColors.ocean, prominent: true)
        _ = LFWEmptyState(symbol: "star", title: "Empty", prominent: true) { EmptyView() }
        _ = LFWStepRow(number: 1, title: "**Open** Settings", detail: "Then tap the toggle.")
        _ = LFWCardModifier()
        _ = EmptyView().lfwCard()
        _ = EmptyView().lfwCard(fill: .white, cornerRadius: LFWRadius.card, padding: 0)
    }

    // LFWStepRow's a11y label uses rendered text, not raw markdown, so VoiceOver
    // doesn't speak the "**" in a title like "**Open** Settings". Guards the mechanism.
    func test_markdownStripsToPlainTextForAccessibility() {
        let rendered = String((try! AttributedString(markdown: "**Open** Settings")).characters)
        XCTAssertEqual(rendered, "Open Settings")
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
