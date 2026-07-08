# Contributing

Stop Political Spam Texts is **MIT-licensed open source**. Fork it, steal it,
ship your own variant, improve the classifier — please do. This is a public
utility, not a walled garden.

By participating you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

## Support & feedback

- **[GitHub Issues](https://github.com/lukefwalton/stop-political-texts/issues)** —
  bugs, false positives/negatives, questions.
- **[luke@lukefwalton.com](mailto:luke@lukefwalton.com)** — same, or if you prefer email.

## Pull requests

PRs welcome — especially classifier fixes, tests, and docs. Good PRs usually include:

- A short explanation of the user problem (false positive, false negative, setup confusion).
- Tests for classifier, normalization, URL extraction, sender analysis, or config changes.
- Confirmation that `bash scripts/privacy_check.sh` still passes.

## Forking for the App Store

Go for it. A fork is its own app: change `bundleIdPrefix` in `project.yml`, update
the App Group id in both `.entitlements` files, use your own signing identity, and
write your own App Store privacy disclosures. MIT permits this explicitly.

## Development

```bash
brew install xcodegen
cp project.local.yml.example project.local.yml
# Edit project.local.yml — set DEVELOPMENT_TEAM (never commit this file).
bash scripts/generate.sh
open StopPoliticalSpamTexts.xcodeproj
```

```bash
xcodebuild test -scheme StopPoliticalSpamTexts \
  -destination 'platform=iOS Simulator,name=iPhone 15'
bash scripts/privacy_check.sh
```

## Ground rules (keep the privacy promise)

- Message filtering stays entirely on device.
- No analytics, tracking, ads, accounts, push, or backend dependencies.
- No persistence of message bodies, senders, normalized text, or domains.

See [LICENSE](LICENSE) and [DCO.md](DCO.md). Sign off commits with `git commit -s`.

Found a security issue? Please report it privately — see [SECURITY.md](SECURITY.md).
