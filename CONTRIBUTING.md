# Contributing

Stop Political Spam Texts is **public source, copyright Luke F. Walton** — not
open source (no MIT or similar license). The code is visible so you can verify
the privacy posture; the App Store build is the official release.

## Support & feedback

Having a problem with the app or the repo?

- **[GitHub Issues](https://github.com/lukefwalton/stop-political-texts/issues)** —
  bugs, questions, anything reproducible (include iOS version and app version
  when you can).
- **[luke@lukefwalton.com](mailto:luke@lukefwalton.com)** — same, or if you prefer
  email. Preferred for security or privacy concerns.

## What we do not accept (without prior agreement)

- Pull requests that add features, refactors, or dependency changes.
- Forks published to the App Store or redistributed as competing products.
- Use of this codebase beyond personal local audit/build without written permission.

If you have a concrete fix and believe it should land, open an issue first.

## Building locally (audit / development)

Generate the Xcode project with XcodeGen:

```bash
brew install xcodegen
cp project.local.yml.example project.local.yml
# Edit project.local.yml — set your DEVELOPMENT_TEAM (never commit this file).
xcodegen generate
open StopPoliticalSpamTexts.xcodeproj
```

Run unit tests with `⌘U`, or:

```bash
xcodebuild test -scheme StopPoliticalSpamTexts \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Before shipping privacy-sensitive changes, run:

```bash
bash scripts/privacy_check.sh
```

CI runs the privacy grep (`.github/workflows/checks.yml`) on every push.

## Architecture ground rules (if we do accept a change)

- Keep message filtering entirely on device.
- No analytics, tracking, ads, accounts, push, or backend dependencies.
- No persistence of message bodies, senders, normalized text, or domains.
- Classifier changes need focused tests.

See [LICENSE](LICENSE) for terms. Third-party references are in [NOTICE](NOTICE).
