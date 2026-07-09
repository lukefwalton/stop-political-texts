import SwiftUI
import UIKit
import LFWDesignSystem

/// Self-serve diagnostic for the most common support ticket: "I installed it and
/// I'm still getting texts." The user pastes one that got through; the screen
/// runs it through the *exact* extension path (`MessageFilterPipeline`, which
/// loads the shared config and applies the same body cap) and tells them which
/// of three problems they have — a setup gap in iOS Settings, the in-app toggle
/// being off, or a genuine classifier miss.
///
/// Nothing is persisted. The classifier is a pure function of (sender, body,
/// config); the pasted text lives only in view state.
struct StillGettingTextsView: View {
    @Environment(\.openURL) private var openURL
    @State private var draft = ""
    @State private var sender = ""
    @State private var diagnosis: SetupDiagnosis?
    @State private var lastResult: ClassificationResult?

    var body: some View {
        Form {
            Section {
                Text("Paste a political text that still reached your inbox. This checks whether the filter *would* catch it, which tells us where the problem is.")
                    .font(.subheadline)
            }

            Section {
                TextEditor(text: $draft)
                    .frame(minHeight: 120)
                    .autocorrectionDisabled()
                TextField("Sender (optional, e.g. 12345)", text: $sender)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                Button("Check this text") {
                    let trimmedSender = sender.trimmingCharacters(in: .whitespaces)
                    let result = MessageFilterPipeline.classify(
                        sender: trimmedSender.isEmpty ? nil : trimmedSender,
                        body: draft
                    )
                    lastResult = result
                    diagnosis = SetupDiagnosis(result: result)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("The text you got")
            } footer: {
                Text("Nothing you paste here is saved.")
            }

            if let diagnosis {
                diagnosisSection(diagnosis)
            }
        }
        .navigationTitle("Still getting texts?")
    }

    // MARK: - Result

    @ViewBuilder
    private func diagnosisSection(_ diagnosis: SetupDiagnosis) -> some View {
        switch diagnosis {
        case .notActiveInSettings:
            Section {
                resultHeader(
                    symbol: "gearshape.badge.exclamationmark",
                    tint: LFWColors.warning,
                    title: "Looks like a setup problem",
                    message: "The filter would send this to Junk — so if it still reached you, it isn't switched on in iOS Settings yet. Most setup problems come from iOS Settings, not the in-app toggle."
                )
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "arrow.up.forward.app")
                }
                NavigationLink("See the setup steps") { EnableInstructionsView() }
            }

        case .disabledInApp:
            Section {
                resultHeader(
                    symbol: "power",
                    tint: LFWColors.warning,
                    title: "Filtering is turned off in the app",
                    message: "The in-app Filtering switch is off, so nothing is being scored right now. Turn it back on from the home screen, then re-check."
                )
            }

        case .classifierGap:
            Section {
                resultHeader(
                    symbol: "text.magnifyingglass",
                    tint: LFWColors.danger,
                    title: "This one slipped past the rules",
                    message: "Filtering is on and it ran, but this message scored below the bar. You can force texts like it to Junk by adding a word from it to your block list."
                )
                NavigationLink("Add a word to always block") { CustomTermsView() }
                if let reportURL {
                    Link(destination: reportURL) {
                        Label("Report this wording", systemImage: "envelope")
                    }
                }
            } footer: {
                Text("Reports are optional and go to the developer so the built-in rules can improve. Only send wording you're comfortable sharing.")
            }
        }
    }

    private func resultHeader(symbol: String, tint: Color, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title).font(.headline)
            } icon: {
                Image(systemName: symbol)
            }
            .foregroundStyle(tint)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    /// Prefilled support email. Body intentionally omits the pasted text — the
    /// user copies in only what they choose to share.
    private var reportURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "luke@lukefwalton.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Missed political text")
        ]
        return components.url
    }
}
