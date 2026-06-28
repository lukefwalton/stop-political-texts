import SwiftUI

/// Runs the *exact* classifier the extension uses. Input is held only in view
/// state and is never persisted.
struct TestMessageView: View {
    @EnvironmentObject private var model: FilterConfigModel
    @State private var draft = ""
    @State private var sender = ""
    @State private var result: ClassificationResult?
    var screenshotSample: (body: String, sender: String)?

    private let classifier = PoliticalTextClassifier()

    var body: some View {
        Form {
            Section {
                TextEditor(text: $draft)
                    .frame(minHeight: 120)
                    .autocorrectionDisabled()
                Button("Classify") {
                    let trimmedSender = sender.trimmingCharacters(in: .whitespaces)
                    result = classifier.classify(
                        sender: trimmedSender.isEmpty ? nil : trimmedSender,
                        body: draft,
                        config: model.config
                    )
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("Sample message")
            } footer: {
                Text("Nothing you type here is saved.")
            }

            Section {
                TextField("Sender (optional, e.g. 12345)", text: $sender)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
            } header: {
                Text("Sender")
            } footer: {
                Text("Short codes (5–6 digits) and 10-digit numbers nudge the score when political content is present, exactly as the extension sees them. Leave blank to test body only.")
            }

            if let result = result {
                Section("Result") {
                    LabeledContent("Outcome") {
                        // Icon + word so VoiceOver and red-green colorblind users
                        // get the same signal sighted users do.
                        Label {
                            Text(result.isFiltered ? "Filtered" : "Allowed")
                        } icon: {
                            Image(systemName: result.isFiltered
                                  ? "xmark.shield.fill"
                                  : "checkmark.shield.fill")
                        }
                        .foregroundStyle(result.isFiltered ? .red : .green)
                        .accessibilityLabel(result.isFiltered
                                            ? "Outcome: filtered to Junk"
                                            : "Outcome: allowed to inbox")
                    }
                    if result.isFiltered {
                        LabeledContent("Destination", value: "Junk")
                    }
                    LabeledContent("Confidence", value: result.confidence.rawValue.capitalized)
                    if !friendlyMatches(result).isEmpty {
                        LabeledContent("Matched", value: friendlyMatches(result).joined(separator: ", "))
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Classification result")
            }
        }
        .navigationTitle("Test a Message")
        .onAppear {
            guard let screenshotSample, result == nil else { return }
            draft = screenshotSample.body
            sender = screenshotSample.sender
            result = classifier.classify(
                sender: screenshotSample.sender,
                body: screenshotSample.body,
                config: model.config
            )
            #if DEBUG
            ScreenshotAutomation.markReady()
            #endif
        }
    }

    /// Human-readable names for matched rules. The raw score is never shown.
    ///
    /// Built-in rules carry their own `displayName` so a newly added rule shows
    /// up correctly without a parallel table. Synthetic ids (hard-political
    /// shortcuts, sender/URL boosts, the user's custom terms) are not `Rule`
    /// instances — their labels live here.
    private func friendlyMatches(_ result: ClassificationResult) -> [String] {
        let ruleNames: [String: String] = Dictionary(
            uniqueKeysWithValues: RuleSet.rules.map { ($0.id, $0.displayName) }
        )
        let syntheticNames: [String: String] = [
            "hard_political": "Known political platform",
            "sender_shortcode": "Short code sender",
            "sender_10dlc": "10-digit sender",
            "url_shortener_strong": "Shortened link",
            "url_shortener_political": "Shortened link"
        ]
        var seen = Set<String>()
        var names: [String] = []
        for id in result.matchedRules {
            let label: String
            if id.hasPrefix("custom_block:") {
                label = "Your blocked term"
            } else if id.hasPrefix("custom_allow:") {
                label = "Your allowed term"
            } else {
                label = ruleNames[id] ?? syntheticNames[id] ?? id
            }
            if seen.insert(label).inserted {
                names.append(label)
            }
        }
        return names
    }
}
