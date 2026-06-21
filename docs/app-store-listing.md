# App Store listing: Stop Political Spam Texts

Paste-ready copy for App Store Connect. Each section below maps to a Connect
field. Keep this in sync with the app's actual UI and `PRIVACY.md`.

## Before you submit (read once)

- **Price** is set in App Store Connect, not in the description. Apple shows it
  on the product page and it varies by region, so the description omits it on
  purpose.
- **The Privacy Policy URL must be publicly reachable at submission.** This app
  lives in its own repository (`stop-political-texts`). Make sure the repo is
  public — and `PRIVACY.md` reachable at the URL below — before submitting, or
  the reviewer's link returns 404.
- **Keep trademarked platform names** (ActBlue, WinRed, party committee names,
  etc.) out of keywords and marketing copy. The classifier handles them
  internally; Apple flags unauthorized trademarks in keywords.
- **Field limits** for reference: App Name and Subtitle 30 characters each,
  Promotional Text 170 characters, Description 4000 characters, Keywords 100
  bytes.

## App Name (<= 30 chars)

Stop Political Spam Texts

## Subtitle (<= 30 chars)

Block campaign texts

## Promotional Text (<= 170 chars)

A simple, private iPhone filter for political campaign texts. No account, no tracking, no subscription, and no server.

## Keywords (<= 100 bytes, no spaces after commas)

sms,blocker,election,vote,junk,filter,privacy,ballot,pac,poll,donation,fundraiser

> Swapped "campaign" out of the original draft: it already appears in the
> subtitle ("Block campaign texts"), and Apple indexes the name and subtitle for
> search, so repeating it wastes bytes. Replace "fundraiser" with another
> distinct term (e.g. "unwanted" or "robotext") if you prefer. Current length is
> 81 bytes.

## Description (<= 4000 chars)

Political campaign texts are out of control. Stop Political Spam Texts helps move obvious campaign, fundraising, polling, ballot-measure, PAC, party, and election texts from unknown senders out of your main inbox and into Junk.

It runs locally on your iPhone using Apple's built-in SMS filtering system. There is no account, no login, no tracking, no ads, no analytics, and no subscription.

What it does:
- Filters likely political campaign texts from unknown senders
- Sends filtered messages to Junk, not deletion
- Lets you choose Normal or Aggressive filtering
- Lets you turn political categories on or off
- Lets you add your own blocked or allowed terms
- Includes a message tester so you can see how the filter behaves

Privacy:
- No account
- No ads
- No analytics SDKs
- No tracking SDKs
- No server classification
- No message collection
- No persistent message history
- Messages stay on your device

The app does not distinguish between political parties, candidates, or ideologies. Political campaign categories are filtered equally.

Setup note:
Apple requires you to enable SMS filtering manually in Settings. The app includes step-by-step setup instructions.

Open source:
Stop Political Spam Texts is MIT-licensed. Fork it, steal it, improve it — anyone can inspect how it works or ship their own variant.

## Primary Category

Utilities

## Secondary Category

Productivity (optional; leave blank if you prefer)

## Age Rating

4+

## Copyright

© 2026 Luke F. Walton

## Privacy Policy URL

https://github.com/lukefwalton/stop-political-texts/blob/main/PRIVACY.md

> Must be public at submission (see notes above). GitHub renders the `/blob/`
> Markdown view, so a separate hosted page is not required.

## Support URL

https://github.com/lukefwalton/stop-political-texts/issues

> Email: luke@lukefwalton.com. Repo must be public at submission so this link works.

## App Privacy (App Store Connect questionnaire)

- Data collection: **Data Not Collected**
- Tracking: No
- Data Linked to You: None
- Data Not Linked to You: None

Detailed answers:

- Third-party SDKs for analytics, advertising, attribution, or crash reporting? No
- Collects contact information? No
- Collects user content, including messages? No
- Collects identifiers? No
- Collects usage data? No
- Collects diagnostics? No
- Collects sensitive information, including political preferences? No
- Collects location? No
- Collects contacts? No
- Requires account creation? No

> Before claiming "Data Not Collected", confirm the **containing app** ships
> with no network calls and no analytics/crash SDKs, not just the extension.
> `scripts/privacy_check.sh` only enforces the no-network/no-logging rules on the
> Message Filter Extension target.

## App Review Notes

This app is a privacy-first SMS filtering utility for political campaign spam texts from unknown senders.

The app includes two targets:

1. A SwiftUI containing app for setup, settings, category toggles, custom local terms, privacy information, FAQ, and testing sample messages.
2. An ILMessageFilterExtension that classifies eligible unknown-sender SMS locally and returns filter/allow behavior to iOS.

The app does not require an account or login.

The app does not collect, transmit, store, sell, share, or analyze message content, sender information, phone numbers, contacts, political preferences, device identifiers, or usage analytics.

The message filtering extension does not make network requests and does not use analytics, advertising, attribution, or crash-reporting SDKs.

To test without receiving real SMS:

1. Install the app and complete onboarding.
2. Open Settings, then go to Apps > Messages > Unknown & Spam. (On older iOS: Settings > Messages > Unknown & Spam.)
3. Turn on Filter Unknown Senders. (Some iOS versions label this Screen Unknown Senders.)
4. Choose Stop Political Spam Texts as the SMS filter.
5. Return to the app, open Home > Verify Filter, and tap Run verification.

Expected: all built-in samples pass (16/16) with default settings (Filter on, Aggressive strictness, all categories on). Political samples show Outcome: Filtered → Junk; commerce/2FA samples show Allowed → Inbox.

Optional single-message check: Home > Test a Message, paste the sample below, tap Classify.

Example test message:
"Election deadline tonight. Donate now to help our campaign win. Reply STOP to opt out."

Expected result in the in-app tester:
Outcome: Filtered. Destination: Junk.

Filtered texts are routed to Junk by iOS. The app does not delete messages.

Maintainer pre-submit check (optional): from the repo root, run `bash scripts/review_demo.sh`.
