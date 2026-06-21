import SwiftUI

struct EnableInstructionsView: View {
    private let steps: [String] = [
        "Open Settings.",
        "Go to Messages.",
        "Tap Unknown & Spam.",
        "Turn on Filter Unknown Senders.",
        "Choose Stop Political Spam Texts."
    ]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What this does")
                        .font(.headline)
                    Text("Lets iOS send unknown texts to this app. The app then moves likely political campaign texts to Junk.")
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            } footer: {
                Text("iOS does not let apps open the exact Messages filter screen.")
            }

            Section("Required setup") {
                Text("Turn on Apple's SMS filter switch, then pick Stop Political Spam Texts.")
                    .font(.subheadline)
            }

            Section("Path") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Settings > Apps > Messages > Unknown & Spam")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("On older iOS: Settings > Messages > Unknown & Spam")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Steps") {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: 24)
                        Text(step)
                    }
                }
            }
            Section {
                Text("Some iOS versions call the switch Screen Unknown Senders.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink("Common fixes") {
                    CommonFixesView()
                }
            }
        }
        .navigationTitle("Setup")
    }
}
