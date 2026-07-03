import SwiftUI

/// A numbered setup step: a gold badge with the step number, then a title and an
/// optional detail line. The shared building block for "how to enable this" /
/// permission / multi-step setup screens, so every app in the family renders an
/// OS-settings gate the same way instead of a bare numbered `List`.
///
/// Titles and details accept lightweight markdown (e.g. `**Filters**`). Text is
/// semantic (`.primary`/`.secondary`) so a step list reads correctly on a light
/// `Form` or a dark themed background.
public struct LFWStepRow: View {
    public let number: Int
    public let title: String
    public let detail: String?

    public init(number: Int, title: String, detail: String? = nil) {
        self.number = number
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(LFWColors.gold.opacity(0.15))
                Circle()
                    .strokeBorder(LFWColors.gold.opacity(0.55), lineWidth: 1.5)
                Text("\(number)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(LFWColors.gold)
            }
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(attributed(title))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let detail {
                    Text(attributed(detail))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        // Number badge is decorative; expose "step N: title. detail" as one label,
        // built from the RENDERED text (markdown stripped) so VoiceOver reads
        // "Open Settings", not the raw "**Open** Settings".
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Step \(number). \(plain(title))\(detail.map { ". \(plain($0))" } ?? "")"))
    }

    private func attributed(_ markdown: String) -> AttributedString {
        (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }

    /// The rendered plain text of a markdown string (syntax stripped), for the a11y label.
    private func plain(_ markdown: String) -> String {
        String(attributed(markdown).characters)
    }
}
