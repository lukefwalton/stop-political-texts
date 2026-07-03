import SwiftUI

/// The family "card" surface: a rounded container with a soft `deepSea` shadow,
/// sized on `LFWRadius.surface`. Gives every app one card look instead of
/// re-deriving a `RoundedRectangle` fill + shadow with a drifting corner radius
/// (apps had cards at 22, 26, 28… for the same role).
///
/// Apply with `.lfwCard()`. Override the fill for a light page
/// (`.lfwCard(fill: .white)`) or pass a themed surface color; override `padding`
/// when the content manages its own insets (`.lfwCard(padding: 0)`).
public struct LFWCardModifier: ViewModifier {
    public var fill: Color
    public var cornerRadius: CGFloat
    public var padding: CGFloat

    public init(
        fill: Color = LFWColors.paper,
        cornerRadius: CGFloat = LFWRadius.surface,
        padding: CGFloat = 16
    ) {
        self.fill = fill
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .shadow(color: LFWColors.deepSea.opacity(0.10), radius: 12, y: 6)
    }
}

public extension View {
    /// Wrap in the family card surface: a rounded `LFWRadius.surface` fill with a
    /// soft `deepSea` shadow, matching the onboarding/feature-card language.
    func lfwCard(
        fill: Color = LFWColors.paper,
        cornerRadius: CGFloat = LFWRadius.surface,
        padding: CGFloat = 16
    ) -> some View {
        modifier(LFWCardModifier(fill: fill, cornerRadius: cornerRadius, padding: padding))
    }
}
