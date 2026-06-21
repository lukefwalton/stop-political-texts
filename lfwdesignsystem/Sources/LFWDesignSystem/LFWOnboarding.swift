import SwiftUI

// MARK: - Scaffold

/// The hero layout every onboarding screen in the family uses: a circular
/// glyph at the top, a gold kicker, a rounded headline, a content slot, then
/// a pinned footer (typically a CTA pill).
///
/// Designed for the `deepSea → ocean` gradient background. Use
/// `LFWOnboardingBackground` for the matching motion layer.
public struct LFWOnboardingScaffold<Content: View, Footer: View>: View {
    public let symbol: String
    public let eyebrow: String
    public let title: String
    public let content: Content
    public let footer: Footer

    public init(
        symbol: String,
        eyebrow: String,
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.symbol = symbol
        self.eyebrow = eyebrow
        self.title = title
        self.content = content()
        self.footer = footer()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 44)
            LFWHeroIcon(symbol: symbol)

            VStack(spacing: 14) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.heavy))
                    .kerning(2)
                    .foregroundStyle(LFWColors.gold)
                    .multilineTextAlignment(.center)
                Text(title)
                    .font(.system(size: 33, weight: .bold, design: .rounded))
                    .foregroundStyle(LFWColors.paper)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                content
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)

            Spacer(minLength: 24)
            footer
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Hero icon

/// The big circular glyph at the top of every onboarding screen.
public struct LFWHeroIcon: View {
    public let symbol: String

    public init(symbol: String) { self.symbol = symbol }

    public var body: some View {
        ZStack {
            Circle()
                .fill(LFWColors.paper.opacity(0.10))
            Circle()
                .strokeBorder(LFWColors.gold.opacity(0.55), lineWidth: 1.5)
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(LFWColors.paper)
        }
        .frame(width: 112, height: 112)
        .shadow(color: LFWColors.deepSea.opacity(0.45), radius: 14, y: 8)
    }
}

// MARK: - Supporting text

/// The body copy that sits below the headline on a hero screen.
public struct LFWOnboardingMessage: View {
    public let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .regular, design: .rounded))
            .foregroundStyle(LFWColors.paper.opacity(0.78))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 2)
    }
}

// MARK: - Feature row

/// A bulleted feature line: SF Symbol on the left, label on the right, soft
/// translucent paper card behind it. Used in the "what you'll get" lists.
public struct LFWFeatureRow: View {
    public let symbol: String
    public let text: String

    public init(symbol: String, text: String) {
        self.symbol = symbol
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LFWColors.gold)
                .frame(width: 28)
            Text(attributed(text))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(LFWColors.paper)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: LFWRadius.card, style: .continuous)
                .fill(LFWColors.paper.opacity(0.07))
        )
    }

    private func attributed(_ markdown: String) -> AttributedString {
        (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}

// MARK: - Page dots

/// The pill-and-dots indicator under a paged onboarding flow.
public struct LFWPageDots: View {
    public let count: Int
    public let index: Int

    public init(count: Int, index: Int) {
        self.count = count
        self.index = index
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? LFWColors.gold : LFWColors.paper.opacity(0.30))
                    .frame(width: dot == index ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
    }
}
