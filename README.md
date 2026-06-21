# Stop Political Spam Texts (iOS)

A privacy-first iOS app that routes obvious political campaign, donation,
polling, PAC, ballot-measure, proposition, and election texts from **unknown
senders** out of your main inbox. This happens entirely on device.

> No account. No tracking. No server. No political profiling. Messages stay on
> your device.

It's also **open source (MIT)**. The full code is public so anyone can verify
those privacy claims rather than take them on faith.

## Why this exists

Political campaign texts are relentless, repetitive, and hard to stop. Opting
out of one list does nothing about the next. Most SMS filters hand you a box of
keywords and regex and make the rules your problem.

Stop Political Spam Texts is narrower on purpose. It targets obvious political
campaign, fundraising, polling, ballot-measure, PAC, party, and election texts
from **unknown senders** and routes them to Junk. No accounts, no subscriptions,
no servers, no message collection. iOS only ever hands the filter unknown-sender
messages, so people already in your contacts are never touched.

## How it works

Two targets share one classifier:

- **StopPoliticalSpamTexts**: SwiftUI containing app. Configures the filter and
  lets you test sample messages with the *exact same* classifier the extension
  uses.
- **StopPoliticalSpamTextsMessageFilter**: an `ILMessageFilterExtension`. iOS
  hands it unknown-sender SMS; it returns `.junk` or `.none` and forgets
  everything. No network, no persistence.

Shared config flows through the App Group
`group.com.lukewalton.stoppoliticalspamtexts`.

```
App ──┐                              ┌── Extension
      ├─ Classifier/ (shared) ───────┤
      └─ Storage/ SharedConfigStore ─┘   (App Group JSON)
```

## Building

The Xcode project is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open StopPoliticalSpamTexts.xcodeproj
```

Then set your `DEVELOPMENT_TEAM` in Signing & Capabilities. The App Group
capability is pre-declared in the `.entitlements` files for both targets.

Run the unit tests with `⌘U` or:

```bash
xcodebuild test -scheme StopPoliticalSpamTexts \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## The classifier

A weighted, token/phrase-aware rules engine. Decision pipeline
(`PoliticalTextClassifier.classify`):

1. Disabled / empty body → allow
2. Normalize, extract URLs, analyze sender shape
3. Hard-political platforms/domains (ActBlue, WinRed, DNC, …) → filter (floor 8)
4. Critical allowlist (auth/commerce/emergency) → allow, unless hard political
5. Score enabled rules (non-pairing, then pairing-required ballot rules)
6. Shortened-link boost (no network expansion) + sender boost (only with
   political context)
7. Custom blocked (+4) / allowed (−4, floored, no override on hard political)
8. Threshold: aggressive ≥ 4, normal ≥ 6

### Notable implementation decisions

- **Letter boundaries, not `\b`.** Terms match only when not abutted by a
  letter, so `maga` matches `MAGA2026` (a campaign code) but not `magazine`;
  `pac` ≠ `package`; `prop` ≠ `proper`; `dnc` ≠ `dnce`. Custom user terms get
  the same boundary-aware matching (via `TermMatcher`) and are normalized like
  the message text first — blocking `vote` does not also block `devote`.
- **Ballot rules are split** into a measure noun and a directional call (both
  `requiresPairing`). A directive like "no on Proposition 4" only scores when
  paired with another signal (here, "Reply STOP").
- **SMS mechanics never filter alone** and do not count as political context for
  the sender boost.

## Privacy

The extension performs **no network calls**, imports no analytics or
crash-reporting SDKs, and persists nothing. Only user preferences are stored,
in the App Group. Run the release grep check from the repo's `PRIVACY.md`
before shipping.

This is a personal project by Luke Walton, founder of Surmado. It is **not** a
Surmado product.

## Built to keep working

By design, this app doesn't depend on any single person or company staying
involved to keep doing its job.

- **Your copy is self-contained.** Everything runs on your device, with no
  server or account behind it, so an installed copy keeps filtering on its own.
  There's nothing that can be switched off remotely.
- **The code stays open.** It's MIT-licensed and public, so it can't quietly
  disappear. Building your own copy takes a few minutes — see
  [Building](#building): `brew install xcodegen`, `xcodegen generate`, set your
  signing team, and run it on your device.
- **Anyone can carry it forward.** Forks and reuse are welcome under the MIT
  license. A fork is its own app with its own App Store review and privacy
  disclosures; change `bundleIdPrefix` in `project.yml` and the App Group id to
  make it your own.

The value here lives in your pocket and in the open code — not in a subscription
or a server you have to trust someone to keep running.

## FAQ

Full list in [docs/FAQ.md](docs/FAQ.md). The one people ask most:

**How is this different from Bouncer or other SMS filters?** General-purpose
filters like Bouncer and Veto give you allow and block word lists to catch any
unwanted SMS, so you write the rules yourself. Stop Political Spam Texts ships a
maintained classifier tuned for political campaign, fundraising, polling,
ballot-measure, PAC, party, and election texts, so political detection works out
of the box (custom terms optional). Both approaches are privacy-friendly and
local-first, but this app is narrower by design and credits Bouncer and Veto as
design inspiration (see Acknowledgements below).

## License

Open source under the [MIT License](LICENSE). The source is public so users can
audit the privacy guarantees (no network in the extension, no tracking, no data
business). The App Store build is sold for $0.99, paid once purely to support
maintenance, not to monetize data. MIT permits forks and reuse; any fork is a
separate app with its own App Store review and privacy disclosures.

Contributions are welcome under the project's [contribution guidelines](CONTRIBUTING.md).
Commits use a lightweight [Developer Certificate of Origin](DCO.md) sign-off.

## Acknowledgements

No third-party code is bundled. See [NOTICE](NOTICE) for credits and license
notes. Some design patterns were informed by
MIT-licensed open-source iOS message filters, notably
[Veto](https://github.com/signalblur/Veto) and
[Bouncer](https://github.com/afterxleep/Bouncer). Specifically: allow-before-deny
precedence, an offline CI grep to guarantee the no-network promise,
until-first-unlock file protection so the extension can read settings on a
locked device, and Unicode diacritic folding during normalization.

High-signal terms and the political-domain blocklist draw on public-domain U.S.
government sources: the [FEC disclaimer rules](https://www.fec.gov/help-candidates-and-committees/advertising-and-disclaimers/)
("paid for by", "not authorized by any candidate") and the
[FCC political robotext rules](https://www.fcc.gov/consumers/guides/political-campaign-robocalls-and-robotexts-rules)
(opt-out language). No copyrighted or restrictively-licensed datasets are used.
