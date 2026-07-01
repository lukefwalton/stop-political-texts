#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
import CoreText

/// Variable-font axis control for SwiftUI.
///
/// SwiftUI has **no** first-class API for setting an arbitrary variation-axis
/// value on a custom font: `Font.custom` only picks family + size, `.fontWeight`
/// snaps to discrete cases, and `.fontWidth` (iOS 16) only reaches the system
/// font's width axis. iOS 17/18 added nothing. The only route is Core Text:
/// build a `UIFont` from a `UIFontDescriptor` carrying `kCTFontVariationAttribute`
/// (a map of *integer* axis tags → values), then bridge to SwiftUI with
/// `Font(uiFont)`.
///
/// All fonts shipped here are SIL OFL 1.1 (see LFWTypeface for the full set).
public enum LFWVariableFont {

    /// Pack a four-character axis code ("wght") into its Core Text integer tag.
    /// The bytes are folded big-endian — `'wght'` becomes `0x77676874`.
    public static func tag(_ code: String) -> Int {
        precondition(code.utf8.count == 4, "axis code must be exactly 4 ASCII characters")
        return code.utf8.reduce(0) { ($0 << 8) + Int($1) }
    }

    /// Common registered axis tags, precomputed.
    public static let weight = tag("wght")
    public static let opticalSize = tag("opsz")
    public static let width = tag("wdth")
    public static let slant = tag("slnt")
    public static let italic = tag("ital")
    /// Fraunces' custom axes.
    public static let soft = tag("SOFT")
    public static let wonk = tag("WONK")
    /// Recursive's custom axes.
    public static let casual = tag("CASL")
    public static let mono = tag("MONO")
    public static let cursive = tag("CRSV")

    /// Whether a font family is actually registered (bundled) at runtime. Used so
    /// the typography layer can fall back to a system face instead of silently
    /// rendering the system font under a custom name.
    public static func isRegistered(_ family: String) -> Bool {
        #if canImport(UIKit)
        return resolvedName(for: family) != nil
        #else
        // Off UIKit there is no registered custom font, so report false: the
        // typography layer then uses its system-face fallback (correct role
        // weight/design) instead of the variable-font path, which would degrade
        // to a plain `.system(size:)` and drop those semantics.
        return false
        #endif
    }

    /// PostScript name to pass to Core Text / `UIFontDescriptor` for a bundled
    /// variable font. Family names like `"Inter"` are not always valid CT names —
    /// Inter's VF registers as `"InterVariable"` under the `"Inter"` family.
    public static func resolvedName(for family: String, size: CGFloat = 24) -> String? {
        #if canImport(UIKit)
        if let font = UIFont(name: family, size: size), hasVariationAxes(font) {
            return font.fontName
        }
        for name in UIFont.fontNames(forFamilyName: family) {
            if let font = UIFont(name: name, size: size), hasVariationAxes(font) {
                return name
            }
        }
        if let font = UIFont(name: family, size: size) { return font.fontName }
        return UIFont.fontNames(forFamilyName: family).first
        #else
        return family
        #endif
    }

    #if canImport(UIKit)
    private static func hasVariationAxes(_ font: UIFont) -> Bool {
        guard let raw = CTFontCopyVariationAxes(font as CTFont) as? [[CFString: Any]] else { return false }
        return !raw.isEmpty
    }
    #endif

    /// The variation axes a registered font exposes, keyed by 4-char code →
    /// (min, default, max). Empty if the font isn't found. For diagnostics — log
    /// once at startup to confirm the real tags/ranges of a bundled font.
    public static func axes(of family: String, size: CGFloat = 24) -> [String: (min: Double, default: Double, max: Double)] {
        var result: [String: (min: Double, default: Double, max: Double)] = [:]
        guard let name = resolvedName(for: family, size: size) else { return result }
        let ct = CTFontCreateWithName(name as CFString, size, nil)
        guard let raw = CTFontCopyVariationAxes(ct) as? [[CFString: Any]] else { return result }
        for axis in raw {
            guard let id = axis[kCTFontVariationAxisIdentifierKey] as? Int else { continue }
            let lo = (axis[kCTFontVariationAxisMinimumValueKey] as? Double) ?? 0
            let mid = (axis[kCTFontVariationAxisDefaultValueKey] as? Double) ?? 0
            let hi = (axis[kCTFontVariationAxisMaximumValueKey] as? Double) ?? 0
            result[code(from: id)] = (lo, mid, hi)
        }
        return result
    }

    /// Reverse of `tag(_:)` — unpack an integer tag back into its 4-char code.
    static func code(from tag: Int) -> String {
        let bytes = [(tag >> 24) & 0xFF, (tag >> 16) & 0xFF, (tag >> 8) & 0xFF, tag & 0xFF]
        return String(bytes.compactMap { UnicodeScalar($0).map(Character.init) })
    }
}

public extension Font {
    /// A custom variable font at arbitrary axis values, bridged into SwiftUI.
    ///
    /// `axes` maps Core Text integer tags (`LFWVariableFont.weight`, …) to values.
    /// If `name` isn't a registered family the result is a system font of `size`
    /// (UIKit's documented fallback), so callers that care should gate on
    /// `LFWVariableFont.isRegistered(_:)` first.
    static func lfwVariable(_ name: String, size: CGFloat, axes: [Int: CGFloat]) -> Font {
        #if canImport(UIKit)
        return Font(LFWVariableFontCache.shared.font(name: name, size: size, axes: axes))
        #else
        return .system(size: size)
        #endif
    }
}

#if canImport(UIKit)
/// Memoizes `UIFont` construction by (name, size, quantized axes). `CTFont`/
/// `UIFont` creation is comparatively expensive, and an animating axis rebuilds
/// the font every frame — without a cache that drops frames. Axis values are
/// quantized to whole units so a smooth animation reuses a bounded set of fonts.
final class LFWVariableFontCache {
    static let shared = LFWVariableFontCache()

    private let lock = NSLock()
    private var cache: [String: UIFont] = [:]

    func font(name: String, size: CGFloat, axes: [Int: CGFloat]) -> UIFont {
        let resolved = LFWVariableFont.resolvedName(for: name, size: size) ?? name
        let key = cacheKey(name: resolved, size: size, axes: axes)
        lock.lock(); defer { lock.unlock() }
        if let hit = cache[key] { return hit }

        var variations: [Int: CGFloat] = [:]
        for (tag, value) in axes { variations[tag] = value.rounded() }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: resolved,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variations
        ])
        let font = UIFont(descriptor: descriptor, size: size)
        cache[key] = font
        // Bound the cache so a wild animation can't grow it without limit.
        if cache.count > 512 { cache.removeAll(keepingCapacity: true) }
        return font
    }

    private func cacheKey(name: String, size: CGFloat, axes: [Int: CGFloat]) -> String {
        // Axis values are quantized to whole units (matching the rounding applied
        // when the font is built) so an animating axis reuses a bounded set of
        // fonts. Size is NOT animated, so it's keyed at full precision — otherwise
        // 17.2 and 17.8 would collide onto one cached font at the wrong point size.
        let axisPart = axes.keys.sorted().map { "\($0):\(Int(axes[$0]!.rounded()))" }.joined(separator: ",")
        return "\(name)|\(size)|\(axisPart)"
    }
}
#endif

/// Animates a single variable-font axis. SwiftUI cannot interpolate a `Font`, so
/// the *axis value* is the `animatableData` and the font is rebuilt (from cache)
/// each interpolation tick. Use sparingly — one hero label at a time, not lists.
public struct LFWVariableAxisModifier: ViewModifier, Animatable {
    public var value: CGFloat
    let name: String
    let size: CGFloat
    let tag: Int
    let staticAxes: [Int: CGFloat]

    public var animatableData: CGFloat {
        get { value }
        set { value = newValue }
    }

    public init(value: CGFloat, name: String, size: CGFloat, tag: Int, staticAxes: [Int: CGFloat] = [:]) {
        self.value = value
        self.name = name
        self.size = size
        self.tag = tag
        self.staticAxes = staticAxes
    }

    public func body(content: Content) -> some View {
        var axes = staticAxes
        axes[tag] = value
        return content.font(.lfwVariable(name, size: size, axes: axes))
    }
}

public extension View {
    /// Render `self` in a variable font whose `tag` axis animates to `value`
    /// (with `staticAxes` held fixed). Drives the hero word's weight "breathe".
    func lfwVariableAxis(_ value: CGFloat, name: String, size: CGFloat,
                         tag: Int, staticAxes: [Int: CGFloat] = [:]) -> some View {
        modifier(LFWVariableAxisModifier(value: value, name: name, size: size, tag: tag, staticAxes: staticAxes))
    }
}
