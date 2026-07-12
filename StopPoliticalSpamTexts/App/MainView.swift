import SwiftUI
import UIKit
import LFWDesignSystem

struct MainView: View {
    @EnvironmentObject private var model: FilterConfigModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stop Political Spam Texts")
                        .font(.title2.bold())
                    Text("Sends likely campaign texts from unknown senders to your Junk folder. Texts from your contacts are never touched.")
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
                            .foregroundStyle(LFWColors.warning)
                    }
                }
            }

            // The step that actually makes filtering work lives in iOS Settings,
            // not the in-app toggle below it. Lead with it so no one mistakes the
            // toggle for the activation switch.
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("Turn on filtering in iOS Settings")
                            .font(.headline)
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                    .foregroundStyle(BrandColor.gold)
                    Text("This app only filters once you select it as your SMS filter. iOS won't let us do it for you — it's one short trip to Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                // The setup steps are the primary action: the deep link below
                // can only land on this app's own Settings page, so the steps
                // are what actually get people to the filter picker.
                NavigationLink {
                    EnableInstructionsView()
                } label: {
                    Label("See the setup steps", systemImage: "list.number")
                        .fontWeight(.semibold)
                }
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label(SetupInstructions.settingsButtonLabel, systemImage: "arrow.up.forward.app")
                }
                NavigationLink("Still getting texts?") { StillGettingTextsView() }
            } header: {
                Text("Activation")
            } footer: {
                Text(SetupInstructions.settingsButtonNote)
            }

            Section {
                Toggle("Filtering rules", isOn: Binding(
                    get: { model.config.enabled },
                    set: { model.config.enabled = $0; LFWHaptics.selection() }))
            } header: {
                Text("App controls")
            } footer: {
                Text("Pauses the app's rules. This does not remove the app as your SMS filter in iOS Settings.")
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
