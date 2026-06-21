# Contributing

Thanks for considering a contribution to Stop Political Spam Texts.

This is a small, local-first iOS utility app. The project values low contributor
friction, clear privacy guarantees, and changes that keep the app simple enough
for users to understand and audit.

## Ground rules

- Keep message filtering entirely on device.
- Do not add analytics, tracking, ads, accounts, push notifications, or backend
  dependencies.
- Do not persist message bodies, sender details, normalized message text, or
  extracted domains.
- Keep classifier changes explainable and covered by focused tests.
- Prefer small pull requests with a clear user-facing reason.

## Development

Generate the Xcode project with XcodeGen:

```bash
brew install xcodegen
xcodegen generate
open StopPoliticalSpamTexts.xcodeproj
```

Run the unit tests with Xcode or:

```bash
xcodebuild test -scheme StopPoliticalSpamTexts \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Before shipping privacy-sensitive changes, run:

```bash
bash scripts/privacy_check.sh
```

## Pull requests

Good pull requests usually include:

- A short explanation of the user problem or false positive/false negative being
  addressed.
- Tests for classifier, normalization, URL extraction, sender analysis, or config
  migration changes when relevant.
- Screenshots for visible UI changes.
- Confirmation that the privacy doctrine in `PRIVACY.md` still holds.

## Developer Certificate of Origin

This project uses the Developer Certificate of Origin instead of a contributor
license agreement. By signing off a commit, you certify that you have the right
to submit the contribution under this project's license.

Sign off commits with:

```bash
git commit -s
```

See `DCO.md` for the full text.
