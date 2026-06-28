import SwiftUI
import UIKit
import LFWDesignSystem

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
                    message: "Pay once and you're done. There's no account to make and nothing to cancel later.",
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
            LFWOnboardingMessage("Let's rescue you from it.")
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
            LFWOnboardingMessage("One short trip to Settings and you're protected. We'll show you exactly what to tap.")
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

    private let steps: [String] = [
        "Open **Settings**.",
        "Tap **Apps**, then **Messages**.",
        "Scroll to **Unknown Senders**.",
        "Tap **Text Message Filter**.",
        "Choose **Stop Political Spam Texts**."
    ]

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

                VStack(spacing: 8) {
                    Button(action: openSettings) {
                        Label("Open Settings", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.lfwCTA(filled: false))

                    Text("Opens the Settings app to save you a step. iOS won't let us jump straight to the Messages filter, so tap through from there.")
                        .font(.footnote)
                        .foregroundStyle(BrandColor.paper.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)

                Button("All done", action: onDone)
                    .buttonStyle(.lfwCTA)
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
