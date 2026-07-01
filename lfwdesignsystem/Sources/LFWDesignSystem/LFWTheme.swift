import SwiftUI

/// The curated set of OFL variable typefaces the user can choose between.
/// `family` is the runtime font family name to pass to Core Text; if the font
/// isn't bundled, the typography layer falls back to a system face of the same
/// `kind` (serif/sans/rounded), so the app stays legible before fonts are added.
public enum LFWTypeface: String, Codable, CaseIterable, Identifiable, Sendable {
    case fraunces
    case literata
    case newsreader
    case sourceSerif4
    case inter
    case sourceSans3
    case recursive

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fraunces:       return "Fraunces"
        case .literata:       return "Literata"
        case .newsreader:     return "Newsreader"
        case .sourceSerif4:   return "Source Serif 4"
        case .inter:          return "Inter"
        case .sourceSans3:    return "Source Sans 3"
        case .recursive:      return "Recursive"
        }
    }

    /// Runtime font family name (the variable font's default named instance).
    /// Confirm with `LFWVariableFont.axes(of:)` after bundling — a wrong name
    /// silently falls back to the system font.
    public var family: String {
        switch self {
        case .fraunces:       return "Fraunces"
        case .literata:       return "Literata"
        case .newsreader:     return "Newsreader"
        case .sourceSerif4:   return "Source Serif 4 Variable"
        case .inter:          return "Inter Variable"
        case .sourceSans3:    return "SourceSans3VF"
        case .recursive:      return "Recursive"
        }
    }

    /// Basename of the bundled variable-font file in `WordOfTheDay/Resources/Fonts/`.
    /// Kept in sync with `scripts/fetch_fonts.sh` and `UIAppFonts` via
    /// `scripts/check_fonts_sync.sh`.
    public var bundledFileName: String {
        switch self {
        case .fraunces:       return "Fraunces.ttf"
        case .literata:       return "Literata.ttf"
        case .newsreader:     return "Newsreader.ttf"
        case .sourceSerif4:   return "SourceSerif4.ttf"
        case .inter:          return "Inter.ttf"
        case .sourceSans3:    return "SourceSans3.ttf"
        case .recursive:      return "Recursive.ttf"
        }
    }

    public enum Kind: Sendable { case serif, sans }

    public var kind: Kind {
        switch self {
        case .fraunces, .literata, .newsreader, .sourceSerif4: return .serif
        case .inter, .sourceSans3, .recursive:                 return .sans
        }
    }

    /// The system fallback design used when the bundled font is absent.
    public var fallbackDesign: Font.Design {
        switch kind {
        case .serif: return .serif
        case .sans:  return .rounded
        }
    }

    /// Whether this face exposes the optical-size axis (used for the hero word).
    public var hasOpticalSize: Bool {
        switch self {
        case .fraunces, .literata, .newsreader, .sourceSerif4, .inter: return true
        case .sourceSans3, .recursive: return false
        }
    }
}

/// A bounded set of color personalities, all built off the `LFWColors` family so
/// "Deep Sea" is literally the existing onboarding gradient. Not a free color
/// wheel — presets plus an optional accent-hue nudge.
public enum LFWPalette: String, Codable, CaseIterable, Identifiable, Sendable {
    case deepSea
    case paper
    case dusk
    case sepia
    case highContrast
    case forest
    case dawn
    case grape

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .deepSea:      return "Deep Sea"
        case .paper:        return "Paper"
        case .dusk:         return "Dusk"
        case .sepia:        return "Sepia"
        case .highContrast: return "High Contrast"
        case .forest:       return "Forest"
        case .dawn:         return "Dawn"
        case .grape:        return "Grape"
        }
    }

    public var isDark: Bool {
        switch self {
        case .deepSea, .dusk, .highContrast, .forest, .grape: return true
        case .paper, .sepia, .dawn: return false
        }
    }

    public var colors: LFWPaletteColors {
        switch self {
        case .deepSea:
            return LFWPaletteColors(
                backgroundTop: LFWColors.deepSea, backgroundBottom: LFWColors.ocean,
                surface: LFWColors.paper.opacity(0.08),
                primaryText: LFWColors.paper, secondaryText: LFWColors.paper.opacity(0.72),
                accent: LFWColors.gold)
        case .dusk:
            return LFWPaletteColors(
                backgroundTop: LFWColors.ink, backgroundBottom: LFWColors.traveler,
                surface: LFWColors.paper.opacity(0.08),
                primaryText: LFWColors.paper, secondaryText: LFWColors.paper.opacity(0.70),
                accent: LFWColors.kelp)
        case .highContrast:
            return LFWPaletteColors(
                backgroundTop: Color(lfwHex: 0x000000), backgroundBottom: Color(lfwHex: 0x0A0A0A),
                surface: Color(lfwHex: 0xFFFFFF).opacity(0.10),
                primaryText: Color(lfwHex: 0xFFFFFF), secondaryText: Color(lfwHex: 0xFFFFFF).opacity(0.80),
                accent: LFWColors.gold)
        case .paper:
            return LFWPaletteColors(
                backgroundTop: LFWColors.paper, backgroundBottom: Color(lfwHex: 0xDCEAF3),
                surface: LFWColors.deepSea.opacity(0.05),
                primaryText: LFWColors.deepSea, secondaryText: LFWColors.steel,
                accent: LFWColors.ocean)
        case .sepia:
            return LFWPaletteColors(
                backgroundTop: Color(lfwHex: 0xF6EEDD), backgroundBottom: Color(lfwHex: 0xEADBBF),
                surface: Color(lfwHex: 0x5B4636).opacity(0.06),
                primaryText: Color(lfwHex: 0x4A3B2A), secondaryText: Color(lfwHex: 0x7A6650),
                accent: Color(lfwHex: 0xB2562E))
        case .forest:
            return LFWPaletteColors(
                backgroundTop: Color(lfwHex: 0x0C2A22), backgroundBottom: Color(lfwHex: 0x1C5C44),
                surface: LFWColors.paper.opacity(0.08),
                primaryText: LFWColors.paper, secondaryText: LFWColors.paper.opacity(0.72),
                accent: Color(lfwHex: 0xC7E66B))
        case .dawn:
            return LFWPaletteColors(
                backgroundTop: Color(lfwHex: 0xFFE3D3), backgroundBottom: Color(lfwHex: 0xF7C0C8),
                surface: Color(lfwHex: 0x5B2A3A).opacity(0.06),
                primaryText: Color(lfwHex: 0x4A2533), secondaryText: Color(lfwHex: 0x8A5A66),
                accent: Color(lfwHex: 0xD8537C))
        case .grape:
            return LFWPaletteColors(
                backgroundTop: Color(lfwHex: 0x241248), backgroundBottom: Color(lfwHex: 0x6A1F7A),
                surface: LFWColors.paper.opacity(0.08),
                primaryText: LFWColors.paper, secondaryText: LFWColors.paper.opacity(0.72),
                accent: Color(lfwHex: 0x5FE0C8))
        }
    }
}

/// Concrete colors for a palette. Roles, not raw hexes, so screens stay theme-agnostic.
public struct LFWPaletteColors: Equatable, Sendable {
    public let backgroundTop: Color
    public let backgroundBottom: Color
    public let surface: Color
    public let primaryText: Color
    public let secondaryText: Color
    public let accent: Color

    public init(backgroundTop: Color, backgroundBottom: Color, surface: Color,
                primaryText: Color, secondaryText: Color, accent: Color) {
        self.backgroundTop = backgroundTop
        self.backgroundBottom = backgroundBottom
        self.surface = surface
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.accent = accent
    }
}

/// The user's theme choice. Codable so it round-trips through the App Group
/// defaults and is read identically by the app and the widget.
public struct LFWThemeConfig: Codable, Equatable, Sendable {
    public var typeface: LFWTypeface
    public var palette: LFWPalette
    /// Optional fine-tune of the accent color's hue, in degrees [-180, 180].
    public var accentHueShift: Double

    public init(typeface: LFWTypeface = .fraunces,
                palette: LFWPalette = .deepSea,
                accentHueShift: Double = 0) {
        self.typeface = typeface
        self.palette = palette
        self.accentHueShift = accentHueShift
    }

    /// The family default: Fraunces + Deep Sea, no hue shift.
    public static let `default` = LFWThemeConfig()

    private enum CodingKeys: String, CodingKey {
        case typeface, palette, accentHueShift
    }

    // Tolerant decode: an unknown typeface/palette raw value — from app/widget version
    // skew or a downgrade that doesn't know a newer palette — defaults rather than
    // failing the whole theme decode (which would reset every choice).
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawTypeface = (try? c.decodeIfPresent(String.self, forKey: .typeface)) ?? nil
        let rawPalette = (try? c.decodeIfPresent(String.self, forKey: .palette)) ?? nil
        typeface = rawTypeface.flatMap(LFWTypeface.init(rawValue:)) ?? .fraunces
        palette = rawPalette.flatMap(LFWPalette.init(rawValue:)) ?? .deepSea
        accentHueShift = ((try? c.decodeIfPresent(Double.self, forKey: .accentHueShift)) ?? nil) ?? 0
    }

    /// Palette colors with the accent-hue nudge applied.
    public var colors: LFWPaletteColors {
        let base = palette.colors
        guard accentHueShift != 0 else { return base }
        return LFWPaletteColors(
            backgroundTop: base.backgroundTop, backgroundBottom: base.backgroundBottom,
            surface: base.surface, primaryText: base.primaryText, secondaryText: base.secondaryText,
            accent: base.accent.lfwHueShifted(by: accentHueShift))
    }
}

extension Color {
    /// Rotate a color's hue by `degrees`. Used only for the bounded accent nudge.
    func lfwHueShifted(by degrees: Double) -> Color {
        #if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        let shifted = (h + CGFloat(degrees / 360)).truncatingRemainder(dividingBy: 1)
        let wrapped = shifted < 0 ? shifted + 1 : shifted
        return Color(hue: Double(wrapped), saturation: Double(s), brightness: Double(b), opacity: Double(a))
        #else
        return self
        #endif
    }
}
