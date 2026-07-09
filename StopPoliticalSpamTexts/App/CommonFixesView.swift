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
            "You're already on the most aggressive setting by default. Add a blocked term for the wording it's missing, or run \u{201C}Still getting texts?\u{201D} to check whether it's actually a setup issue."
        )
    ]

    var body: some View {
        List {
            Section {
                Text("Most setup problems come from iOS Settings, not the in-app toggle.")
                    .font(.subheadline)
            }

            Section {
                NavigationLink {
                    StillGettingTextsView()
                } label: {
                    Label("Still getting texts? Run the check", systemImage: "text.magnifyingglass")
                }
            } footer: {
                Text("Paste a text that got through and we'll tell you whether it's a setup problem or a rule gap.")
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
