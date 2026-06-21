import SwiftUI

struct CommonFixesView: View {
    private let fixes: [(title: String, detail: String)] = [
        (
            "Texts are still arriving",
            "Confirm iOS Settings is set to use Stop Political Spam Texts as the SMS filter."
        ),
        (
            "A contact was not filtered",
            "iOS message filters only receive eligible unknown-sender texts. Known contacts can stay in your inbox."
        ),
        (
            "Settings are not saving",
            "Reopen the app. For local debug builds, also confirm the App Group capability is enabled for both targets."
        ),
        (
            "Too much is filtered",
            "Switch Strictness to Normal or add an allowed term."
        ),
        (
            "Not enough is filtered",
            "Switch Strictness to Aggressive or add a blocked term."
        )
    ]

    var body: some View {
        List {
            Section {
                Text("Most setup problems come from iOS Settings, not the in-app toggle.")
                    .font(.subheadline)
            }

            Section("Common fixes") {
                ForEach(fixes, id: \.title) { fix in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fix.title)
                            .font(.headline)
                        Text(fix.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Common Fixes")
    }
}
