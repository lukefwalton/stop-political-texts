import SwiftUI
import LFWDesignSystem

struct EnableInstructionsView: View {
    private let steps = SetupInstructions.plainSteps

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What this does")
                        .font(.headline)
                    Text(SetupInstructions.scopeNote)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            } footer: {
                Text("iOS does not let apps open the exact Messages filter screen.")
            }

            Section("Required setup") {
                Text(SetupInstructions.requiredSetup)
                    .font(.subheadline)
            }

            Section("Path") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(SetupInstructions.currentPath)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(SetupInstructions.olderIOSPath)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Steps") {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    // Shared numbered-step row (gold badge) so this setup screen matches
                    // the onboarding's step treatment instead of a plain numbered list.
                    LFWStepRow(number: index + 1, title: step)
                }
            }
            Section {
                Text(SetupInstructions.filterNameNote)
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
