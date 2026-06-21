# LFWDesignSystem

A tiny SwiftUI design system, vendored into this repo as a copy of the package
the author shares across a small family of apps (`jazzhands-midi-ios`,
`workout-logger`, and this one) so they feel like a family at a glance.

It ships:

- **Palette** — `LFWColors.{ocean, deepSea, gold, paper, ink, traveler, nebula, kelp, steel}`
- **Metrics** — `LFWRadius.{chip, card, surface}`
- **Onboarding kit** — `LFWOnboardingScaffold`, `LFWHeroIcon`,
  `LFWOnboardingMessage`, `LFWFeatureRow`, `LFWPageDots`
- **Background** — `LFWOnboardingBackground` (the shared moving-blob layer)
- **Buttons** — `LFWCTAButtonStyle` / `.buttonStyle(.lfwCTA)`

The app consumes it as a local Swift Package via XcodeGen (`packages:` →
`path: lfwdesignsystem`) and `dependencies: [{ package: LFWDesignSystem }]`.
It's resolved by relative path; because this is a vendored copy of the shared
package, keep it in sync with the upstream copy if you change it in both places.

MIT licensed (see [LICENSE](LICENSE)), same terms as the apps that consume it.

## Family rule of thumb

If a screen exists to *welcome*, *explain*, or *gate* the user (onboarding,
empty states, permission walls), reach for these components — that's where
family resemblance pays off most. App-specific gameplay surfaces (a HUD over
a camera, a workout log row, a Form-based settings page) can still use
domain-specific styling; they just shouldn't pull the family apart at the
front door.
