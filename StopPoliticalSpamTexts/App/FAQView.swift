import SwiftUI

struct FAQView: View {
    private struct QA: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    private let items: [QA] = [
        QA(
            question: "Why is it $0.99?",
            answer: "Because Apple charges me $100 a year to publish apps. The 99 cents helps cover that, nothing more. You pay once, and there is no data business behind it."
        ),
        QA(
            question: "Do you see my texts?",
            answer: "No. Filtering runs entirely on your device. Message content and sender information are never sent to a server and are never stored by the app."
        ),
        QA(
            question: "Is there an account or login?",
            answer: "None. No account, no login, no analytics, no tracking, no ads. There is nothing to sign up for."
        ),
        QA(
            question: "Does it block texts from people I know?",
            answer: "No. iOS only routes texts from unknown senders to filters like this one. Messages from your contacts stay in your inbox."
        ),
        QA(
            question: "Where do filtered texts go?",
            answer: "To the Junk folder under Unknown Senders in Messages. They are still there if you ever want to read them."
        ),
        QA(
            question: "Does it favor a political party?",
            answer: "No. The app does not distinguish between parties, candidates, or ideologies. Every political campaign category is filtered equally."
        ),
        QA(
            question: "Can I turn it off?",
            answer: "Anytime. Flip the toggle in the app, or remove it as your SMS filter in iOS Settings."
        ),
        QA(
            question: "Why do I have to set it up in Settings?",
            answer: "Apple requires you to choose an SMS filter yourself in Settings, and iOS will not let an app open that exact screen. So there is one short trip to Settings, then you are done."
        ),
        QA(
            question: "Is the source code public?",
            answer: "Yes. The full source is published so you can verify every privacy promise for yourself. It is not open source — see the license in the repository."
        )
    ]

    var body: some View {
        List {
            Section {
                Text("Short answers to the things people ask most.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(items) { item in
                    DisclosureGroup {
                        Text(item.answer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } label: {
                        Text(item.question)
                            .font(.headline)
                    }
                }
            }
        }
        .navigationTitle("FAQ")
    }
}
