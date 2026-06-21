import SwiftUI

/// The shared call-to-action button style.
///
/// - Filled (default): solid `paper` pill with a soft `deepSea` shadow, dark
///   text. The primary CTA on every onboarding screen.
/// - Outlined (`filled: false`): transparent pill with a translucent paper
///   stroke and light text. Used for secondary actions on the same screen
///   (e.g. "Open Settings").
public struct LFWCTAButtonStyle: ButtonStyle {
    public var filled: Bool

    public init(filled: Bool = true) {
        self.filled = filled
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(filled ? LFWColors.deepSea : LFWColors.paper)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: LFWRadius.card, style: .continuous)
                    .fill(filled ? LFWColors.paper : Color.white.opacity(0.001))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LFWRadius.card, style: .continuous)
                    .strokeBorder(filled ? Color.clear : LFWColors.paper.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: filled ? LFWColors.deepSea.opacity(0.35) : .clear, radius: 10, y: 6)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == LFWCTAButtonStyle {
    static var lfwCTA: LFWCTAButtonStyle { LFWCTAButtonStyle() }
    static func lfwCTA(filled: Bool) -> LFWCTAButtonStyle { LFWCTAButtonStyle(filled: filled) }
}
