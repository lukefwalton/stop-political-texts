import SwiftUI
import LFWDesignSystem

/// Runs the built-in sample corpus through the same classifier the SMS filter
/// extension uses. Lets App Review verify behavior without receiving real texts.
struct ReviewDemoView: View {
    @EnvironmentObject private var model: FilterConfigModel
    @State private var results: [ClassifierFixtureResult]?
    @State private var hasRun = false
    var autoRunVerification = false

    private var passedCount: Int {
        results?.filter(\.passed).count ?? 0
    }

    private var totalCount: Int {
        results?.count ?? ClassifierFixtures.reviewCorpus.count
    }

    var body: some View {
        Form {
            Section {
                Text("Runs sample political and non-political messages through the exact same on-device classifier the SMS filter uses. No network. Nothing is saved.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Run verification") {
                    runVerification()
                }
                .font(.headline)

                if hasRun {
                    LabeledContent("Result") {
                        Label {
                            Text("\(passedCount)/\(totalCount) passed")
                        } icon: {
                            Image(systemName: passedCount == totalCount
                                  ? "checkmark.circle.fill"
                                  : "xmark.circle.fill")
                        }
                        .foregroundStyle(passedCount == totalCount ? LFWColors.success : LFWColors.warning)
                    }

                    if !model.config.enabled {
                        Text("Filter is off in app settings — samples will show Allowed.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Uses your current Strictness and category settings. Default is Aggressive with all categories on.")
            }

            if let results = results {
                Section("Samples") {
                    ForEach(results, id: \.fixture.id) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: result.passed
                                      ? "checkmark.circle.fill"
                                      : "xmark.circle.fill")
                                    .foregroundStyle(result.passed ? LFWColors.success : LFWColors.danger)
                                Text(result.fixture.label)
                                    .font(.headline)
                            }
                            Text(result.fixture.body)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                            Text("Outcome: \(result.isFiltered ? "Filtered → Junk" : "Allowed → Inbox")")
                                .font(.caption)
                        }
                        .padding(.vertical, 2)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(result.fixture.label). "
                                + (result.passed ? "Passed." : "Failed.")
                                + " Outcome: \(result.isFiltered ? "filtered" : "allowed")."
                        )
                    }
                }
            }
        }
        .navigationTitle("Verify Filter")
        .onAppear {
            if autoRunVerification, !hasRun {
                runVerification()
            }
            #if DEBUG
            if autoRunVerification {
                ScreenshotAutomation.markReady()
            }
            #endif
        }
    }

    private func runVerification() {
        results = ClassifierFixtures.evaluate(config: model.config)
        hasRun = true
    }
}
