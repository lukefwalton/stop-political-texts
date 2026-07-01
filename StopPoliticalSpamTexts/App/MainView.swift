import SwiftUI
import LFWDesignSystem

struct MainView: View {
    @EnvironmentObject private var model: FilterConfigModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stop Political Spam Texts")
                        .font(.title2.bold())
                    Text("Send campaign texts to Junk.")
                        .font(.subheadline)
                    Text("Privacy. No login. No subscription.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if model.saveFailed {
                Section {
                    NavigationLink {
                        CommonFixesView()
                    } label: {
                        Label("Settings issue detected", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section("Status") {
                Toggle("Filter", isOn: Binding(
                    get: { model.config.enabled },
                    set: { model.config.enabled = $0; LFWHaptics.selection() }))
                NavigationLink {
                    EnableInstructionsView()
                } label: {
                    Text("Filter requires setup in iOS Settings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Strictness") {
                Picker("Mode", selection: $model.config.strictness) {
                    Text("Normal").tag(Strictness.normal)
                    Text("Aggressive").tag(Strictness.aggressive)
                }
                .pickerStyle(.segmented)
                Text(model.config.strictness == .aggressive
                     ? "Filters more, catches subtler political texts. May occasionally over-filter."
                     : "Filters only clear political texts. Fewer false positives.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Customization") {
                NavigationLink("Verify Filter") { ReviewDemoView() }
                NavigationLink("Categories") { CategoryTogglesView() }
                NavigationLink("Custom Block List") { CustomTermsView() }
                NavigationLink("Test a Message") { TestMessageView() }
            }

            Section {
                NavigationLink("Privacy") { PrivacyDoctrineView() }
                NavigationLink("FAQ") { FAQView() }
                NavigationLink("About") { AboutView() }
            }
        }
        .navigationTitle("Home")
        .onAppear {
            #if DEBUG
            if ScreenshotRoute.fromLaunchArguments == nil {
                ScreenshotAutomation.markReady()
            }
            #endif
        }
    }
}
