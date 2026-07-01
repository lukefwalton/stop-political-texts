import SwiftUI

/// Semantic type roles. Screens ask for a *role* (`.heroWord`) and the resolver
/// maps it to the current typeface's variable axes — or, if the font isn't
/// bundled, to a system face of the same design. This keeps callers free of font
/// names and axis math.
public enum LFWTextRole: Sendable {
    case heroWord      // the day's word, big and expressive
    case partOfSpeech  // "adjective" — small, accented
    case definition    // the gloss
    case example       // italic-leaning example sentence
    case uiTitle       // screen/section titles
    case uiBody        // standard body copy
    case eyebrow       // gold kerned kicker (matches LFWOnboardingScaffold)

    /// Default point size for the role.
    public var size: CGFloat {
        switch self {
        case .heroWord:     return 56
        case .partOfSpeech: return 15
        case .definition:   return 19
        case .example:      return 16
        case .uiTitle:      return 24
        case .uiBody:       return 17
        case .eyebrow:      return 12
        }
    }

    /// Variable `wght` axis value for the role.
    var weightAxis: CGFloat {
        switch self {
        case .heroWord:     return 560
        case .partOfSpeech: return 620
        case .definition:   return 400
        case .example:      return 380
        case .uiTitle:      return 600
        case .uiBody:       return 440
        case .eyebrow:      return 800
        }
    }

    /// System-font fallback weight for the role.
    var fallbackWeight: Font.Weight {
        switch self {
        case .heroWord:     return .semibold
        case .partOfSpeech: return .bold
        case .definition:   return .regular
        case .example:      return .regular
        case .uiTitle:      return .semibold
        case .uiBody:       return .regular
        case .eyebrow:      return .heavy
        }
    }
}

public enum LFWTypography {
    /// Resolve a `Font` for a role under a typeface, optionally overriding size.
    public static func font(_ role: LFWTextRole, typeface: LFWTypeface, size: CGFloat? = nil) -> Font {
        let pt = size ?? role.size
        let family = typeface.family

        if LFWVariableFont.isRegistered(family) {
            var axes: [Int: CGFloat] = [LFWVariableFont.weight: role.weightAxis]
            if typeface.hasOpticalSize {
                // Tie optical size to point size so big text gets display contrast
                // and small text stays readable.
                axes[LFWVariableFont.opticalSize] = min(max(pt, 9), 144)
            }
            return .lfwVariable(family, size: pt, axes: axes)
        }

        // Graceful fallback: a system face of the same design. New York (serif)
        // is genuinely pretty, so the app still looks intentional sans bundle.
        return .system(size: pt, weight: role.fallbackWeight, design: typeface.fallbackDesign)
    }

    /// The `wght` axis four-char tag, exposed so callers can animate the hero word.
    public static let weightAxisTag = LFWVariableFont.weight
    public static let opticalSizeAxisTag = LFWVariableFont.opticalSize
}

public extension View {
    /// Apply a themed type role. Convenience over `.font(LFWTypography.font(...))`.
    func lfwText(_ role: LFWTextRole, typeface: LFWTypeface, size: CGFloat? = nil) -> some View {
        font(LFWTypography.font(role, typeface: typeface, size: size))
    }
}

/// The themed gradient backdrop. Mirrors `LFWOnboardingBackground`'s moving-blob
/// motion but takes its colors from the user's palette so the whole app (and the
/// onboarding) shares one animated surface.
public struct LFWThemedBackground: View {
    public let config: LFWThemeConfig
    public var animated: Bool
    @State private var drift = false

    public init(config: LFWThemeConfig, animated: Bool = true) {
        self.config = config
        self.animated = animated
    }

    public var body: some View {
        let colors = config.colors
        ZStack {
            LinearGradient(colors: [colors.backgroundTop, colors.backgroundBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            blob(colors.accent.opacity(0.18), size: 320, x: drift ? -120 : -160, y: drift ? -260 : -315)
            blob(colors.backgroundBottom.opacity(0.30), size: 305, x: drift ? 150 : 115, y: drift ? 305 : 350)
            blob(colors.accent.opacity(0.10), size: 225, x: drift ? 145 : 175, y: drift ? -210 : -160)
        }
        .ignoresSafeArea()
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private func blob(_ color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle().fill(color).frame(width: size, height: size).blur(radius: 80).offset(x: x, y: y)
    }
}
