# Privacy Policy

Stop Political Spam Texts does not collect personal information.

The app does not require an account.

The app does not collect your phone number, contacts, email address, messages,
sender information, political preferences, device identifiers, or usage
analytics.

The app does not use analytics SDKs, advertising SDKs, attribution SDKs,
crash-reporting SDKs, or tracking technologies.

Message filtering runs locally on your device. Incoming eligible unknown
messages are evaluated by local rules so iOS can route likely political spam
texts away from your main inbox.

Message content is not sent to any server. Sender information is not sent to any
server. Message content is not stored by the app. Sender information is not
stored by the app.

User preferences, such as strictness, category toggles, and custom local terms,
are stored locally on your device and shared only between the app and its iOS
message-filtering extension for the purpose of applying your selected filtering
settings.

Stop Political Spam Texts does not sell, share, rent, or trade user data.

This is a personal project by Luke F. Walton and is not a Surmado product.

## Contact

Questions: [luke@lukefwalton.com](mailto:luke@lukefwalton.com), or a
[GitHub Issue](https://github.com/lukefwalton/stop-political-texts/issues).

App Store: [Stop Political Spam Texts](https://apps.apple.com/us/app/stop-political-spam-texts/id6782703267) · Website: [lukefwalton.com/stop-political-spam-texts](https://lukefwalton.com/stop-political-spam-texts/)

---

## Privacy doctrine (engineering)

### Extension rules (permanent)

- No `deferQueryRequestToNetwork`
- No `URLSession`
- No `import Sentry`
- No analytics imports
- No `NSLog` / `print` with message body
- No persistence of body, sender, normalized text, or extracted domains
- Return quickly

### App rules (v0)

- No Sentry
- No analytics
- No network calls
- No push notification registration
- No login / account
- No persistent test-message history

### Release grep check

This is automated. `scripts/privacy_check.sh` greps the extension target for
forbidden API usage (network, analytics/crash SDKs, logging) and fails if any is
found. It runs in CI via `.github/workflows/checks.yml` on every push and pull
request, and can be run locally:

```bash
bash scripts/privacy_check.sh
```

The check matches real call sites and imports (e.g. `URLSession(`,
`import Sentry`), not the doc comments that describe the doctrine.
