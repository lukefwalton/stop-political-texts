import SwiftUI

/// The family's empty / "nothing here yet" placeholder. A smaller sibling of the
/// onboarding hero: a circular SF Symbol glyph with a soft accent ring, an optional
/// gold eyebrow, a title, an optional message, and an optional action slot (drop a
/// `.lfwCTA` button in).
///
/// Colors are semantic (`.primary` / `.secondary`) so it reads correctly on a
/// light `Form`, a dark themed background, or anywhere in between — only the ring
/// and glyph take the `accent` (gold by default, the family kicker color). This is
/// the shared alternative to a bare `Text` or an un-styled `ContentUnavailableView`.
///
/// Pass `prominent: true` for the larger, hero-scale variant used as a first-run
/// placeholder that fills a whole tab (the same glyph size as `LFWHeroIcon`), and
/// `eyebrow:` for the small gold kicker above the title. Together these replace the
/// hand-rolled "hero empty state" that apps were otherwise copy-pasting between
/// each other.
public struct LFWEmptyState<Actions: View>: View {
    public let symbol: String
    public let eyebrow: String?
    public let title: String
    public let message: String?
    public let accent: Color
    public let prominent: Bool
    public let actions: Actions

    public init(
        symbol: String,
        title: String,
        message: String? = nil,
        eyebrow: String? = nil,
        accent: Color = LFWColors.gold,
        prominent: Bool = false,
        @ViewBuilder actions: () -> Actions
    ) {
        self.symbol = symbol
        self.eyebrow = eyebrow
        self.title = title
        self.message = message
        self.accent = accent
        self.prominent = prominent
        self.actions = actions()
    }

    private var glyphDiameter: CGFloat { prominent ? 112 : 76 }
    private var glyphPointSize: CGFloat { prominent ? 40 : 30 }
    private var titlePointSize: CGFloat { prominent ? 25 : 19 }

    public var body: some View {
        VStack(spacing: prominent ? 18 : 16) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                Circle()
                    .strokeBorder(accent.opacity(0.45), lineWidth: 1.5)
                Image(systemName: symbol)
                    .font(.system(size: glyphPointSize, weight: .regular))
                    .foregroundStyle(accent)
            }
            .frame(width: glyphDiameter, height: glyphDiameter)
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.caption.weight(.heavy))
                        .kerning(2)
                        .foregroundStyle(accent)
                        .multilineTextAlignment(.center)
                }
                Text(title)
                    .font(.system(size: titlePointSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                if let message {
                    Text(message)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // Combine only the title + message into a single VoiceOver label. The
            // glyph is already hidden, and `actions` stays OUTSIDE this combine so
            // a CTA in the action slot remains separately focusable and actionable.
            .accessibilityElement(children: .combine)

            actions
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

public extension LFWEmptyState where Actions == EmptyView {
    /// Message-only empty state with no action button.
    init(
        symbol: String,
        title: String,
        message: String? = nil,
        eyebrow: String? = nil,
        accent: Color = LFWColors.gold,
        prominent: Bool = false
    ) {
        self.init(symbol: symbol, title: title, message: message, eyebrow: eyebrow,
                  accent: accent, prominent: prominent) { EmptyView() }
    }
}
