import SwiftUI
import UIKit
import LFWDesignSystem

/// The sample the onboarding verify step runs through the classifier. Exposed
/// (internal, not private) so a unit test can pin that it still classifies as
/// filtered under the shipped `FilterConfig.defaults` — the onboarding verify
/// shows its success message only when it does.
enum OnboardingVerification {
    /// Clearly trips the built-in rules (FEC disclaimer + fundraising + SMS
    /// mechanics) under the default Aggressive / all-categories config.
    static let sampleText =
        "Paid for by Friends of Jane. Donate $25 before midnight to help us win — reply STOP to opt out."
}

/// First-run walkthrough. Shown once, then never again (gated by the
/// `hasCompletedOnboarding` flag in `RootView`). Built from the shared
/// `LFWDesignSystem` onboarding kit so this app's welcome flow matches its
/// siblings — same scaffold, same gradient background, same CTA pill.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.openURL) private var openURL

    @State private var page = 0
    @State private var showTroubleshooting = false

    private let pageCount = 6

    var body: some View {
        ZStack {
            LFWOnboardingBackground()

            TabView(selection: $page) {
                WelcomeScreen(action: advance)
                    .tag(0)

                PromiseScreen(
                    symbol: "eye.slash",
                    eyebrow: "No catch",
                    title: "We're not lurkers\nor a subscription.",
                    message: "It's free — pay nothing, ever. There's no account to make and nothing to cancel later.",
                    action: advance
                )
                .tag(1)

                PromiseScreen(
                    symbol: "lock.shield",
                    eyebrow: "Seriously",
                    title: "No logins.\nAnalytics. Nada.",
                    message: "Filtering runs entirely on your device. Nothing about your texts ever leaves your phone.",
                    action: advance
                )
                .tag(2)

                InstallScreen(action: advance)
                    .tag(3)

                ActivateScreen(
                    openSettings: openSettings,
                    onDone: advance,
                    onTrouble: { showTroubleshooting = true }
                )
                .tag(4)

                YourCallScreen(onFinish: finish)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                LFWPageDots(count: pageCount, index: page)
                    .padding(.top, 10)
                Spacer()
            }
            .allowsHitTesting(false)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showTroubleshooting) {
            NavigationStack {
                CommonFixesView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTroubleshooting = false }
                        }
                    }
            }
        }
    }

    private func advance() {
        withAnimation(.easeInOut) { page = min(page + 1, pageCount - 1) }
    }

    private func finish() {
        hasCompletedOnboarding = true
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: - Screens

private struct WelcomeScreen: View {
    let action: () -> Void

    var body: some View {
        LFWOnboardingScaffold(symbol: "shield.lefthalf.filled", eyebrow: "Enough already", title: "We hate\npolitical spam.") {
            LFWOnboardingMessage("Let's move it out of your inbox.")
        } footer: {
            Button("Get started", action: action)
                .buttonStyle(.lfwCTA)
        }
    }
}

private struct PromiseScreen: View {
    let symbol: String
    let eyebrow: String
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        LFWOnboardingScaffold(symbol: symbol, eyebrow: eyebrow, title: title) {
            LFWOnboardingMessage(message)
        } footer: {
            Button("Continue", action: action)
                .buttonStyle(.lfwCTA)
        }
    }
}

private struct InstallScreen: View {
    let action: () -> Void

    var body: some View {
        LFWOnboardingScaffold(symbol: "square.and.arrow.down", eyebrow: "Let's do it", title: "Tap here\nto install.") {
            LFWOnboardingMessage("One short trip to Settings switches it on. iOS only hands us texts from unknown senders, so your contacts are never touched.")
        } footer: {
            Button("Tap here to install", action: action)
                .buttonStyle(.lfwCTA)
        }
    }
}

private struct ActivateScreen: View {
    let openSettings: () -> Void
    let onDone: () -> Void
    let onTrouble: () -> Void

    private let steps = SetupInstructions.steps

    /// nil = not yet checked. Set once the user taps Verify. Gates "All done"
    /// so people engage with the check instead of tapping straight past setup.
    @State private var sampleFiltered: Bool?

    private func runVerify() {
        let result = PoliticalTextClassifier().classify(
            sender: "12345",
            body: OnboardingVerification.sampleText,
            config: .defaults
        )
        sampleFiltered = result.isFiltered
        LFWHaptics.selection()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 56)
                LFWHeroIcon(symbol: "gearshape.fill")

                VStack(spacing: 12) {
                    Text("ALMOST THERE")
                        .font(.caption.weight(.heavy))
                        .kerning(2)
                        .foregroundStyle(BrandColor.gold)
                    Text("Then activate it\nin Settings.")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandColor.paper)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 22)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        StepRow(number: index + 1, text: step)
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BrandColor.paper.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(BrandColor.paper.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 26)

                Text(SetupInstructions.olderIOSFallback)
                    .font(.footnote)
                    .foregroundStyle(BrandColor.paper.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                VStack(spacing: 8) {
                    Button(action: openSettings) {
                        Label(SetupInstructions.settingsButtonLabel, systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.lfwCTA(filled: false))

                    Text(SetupInstructions.settingsButtonNote)
                        .font(.footnote)
                        .foregroundStyle(BrandColor.paper.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)

                VStack(spacing: 10) {
                    Button(action: runVerify) {
                        Label("Verify it recognizes political texts", systemImage: "checkmark.shield")
                    }
                    .buttonStyle(.lfwCTA(filled: false))

                    if let sampleFiltered {
                        VStack(spacing: 8) {
                            Text(sampleFiltered
                                 ? "✓ The filter flagged a sample campaign text — it would go to Junk."
                                 : "The sample wasn't flagged — check your category settings later in the app.")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(sampleFiltered ? BrandColor.gold : BrandColor.paper)
                            Text("This only confirms the app's rules work — we can't see your iOS Settings. If texts keep coming, revisit the steps above. You'll know it's really on when filtered texts start showing up in your Junk folder.")
                                .font(.footnote)
                                .foregroundStyle(BrandColor.paper.opacity(0.6))
                        }
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Button("All done", action: onDone)
                    .buttonStyle(.lfwCTA)
                    .disabled(sampleFiltered == nil)
                    .opacity(sampleFiltered == nil ? 0.5 : 1)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                Button(action: onTrouble) {
                    Text("Having trouble?")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .underline()
                        .foregroundStyle(BrandColor.paper.opacity(0.85))
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct YourCallScreen: View {
    let onFinish: () -> Void

    var body: some View {
        LFWOnboardingScaffold(symbol: "slider.horizontal.3", eyebrow: "Your call", title: "Make it yours.") {
            VStack(spacing: 12) {
                LFWFeatureRow(symbol: "power", text: "Toggle the app on or off anytime.")
                LFWFeatureRow(symbol: "text.badge.plus", text: "Add your own filtered words.")
                LFWFeatureRow(symbol: "speedometer", text: "Get more or less aggressive with it.")
            }
            .padding(.top, 10)
        } footer: {
            Button("Finish Onboarding", action: onFinish)
                .buttonStyle(.lfwCTA)
        }
    }
}

// MARK: - Local supporting view

/// App-specific numbered step row for the activation screen. Not promoted to
/// the shared kit because it's tied to this app's "tap-through Settings"
/// pattern; the other apps don't have an equivalent screen.
private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(BrandColor.deepSea)
                .frame(width: 26, height: 26)
                .background(Circle().fill(BrandColor.gold))
            Text(attributed(text))
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(BrandColor.paper)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func attributed(_ markdown: String) -> AttributedString {
        (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}
