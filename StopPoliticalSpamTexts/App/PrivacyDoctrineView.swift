import SwiftUI

struct PrivacyDoctrineView: View {
    private let promises: [String] = [
        "No login or account.",
        "No analytics SDKs.",
        "No ads.",
        "No tracking SDKs.",
        "No crash-reporting SDKs.",
        "No server classification. Everything runs on your device.",
        "No message collection.",
        "Messages stay on your device."
    ]

    var body: some View {
        List {
            Section {
                Text("Stop Political Spam Texts does not collect personal information.")
                    .font(.headline)
            }
            Section("What we never do") {
                ForEach(promises, id: \.self) { promise in
                    Label(promise, systemImage: "checkmark.shield")
                }
            }
            Section {
                Text("""
                Message filtering runs locally. Incoming eligible unknown messages are evaluated by on-device rules so iOS can route likely political spam texts away from your main inbox.

                Message content and sender information are never sent to a server and are never stored by the app. Your preferences (strictness, category toggles, and custom terms) are stored locally and shared only between the app and its message-filtering extension.

                Stop Political Spam Texts does not sell, share, rent, or trade user data.
                """)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy")
    }
}
