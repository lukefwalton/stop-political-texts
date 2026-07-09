# App Store listing: Stop Political Spam Texts

Paste-ready copy for App Store Connect. Each section below maps to a Connect
field. Keep this in sync with the app's actual UI and `PRIVACY.md`.

## Before you submit (read once)

- **Price** is set in App Store Connect, not in the description. Set to **Free**
  ($0). Apple shows regional pricing on the product page; the description omits
  price on purpose.
- **The Privacy Policy URL must be publicly reachable at submission.** Use
  `https://lukefwalton.com/stop-political-spam-texts/privacy/` (deploy the site
  after merging the product pages).
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

What to expect (please read):
- It works on texts from unknown senders only. Apple never sends messages from your contacts to filters like this, so people you know are never touched.
- Filtered texts are moved to the Junk folder under Unknown Senders — they are sorted out of your main inbox, not blocked or deleted. They are still on your phone if you want to read them.
- You must select the app as your SMS filter in Settings for any of this to happen. Turning on the switch inside the app is not enough on its own.

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

https://lukefwalton.com/stop-political-spam-texts/privacy/

## Support URL

https://lukefwalton.com/stop-political-spam-texts/

> Email: luke@lukefwalton.com · GitHub Issues on the public repo also fine.

## App Store URL (live)

https://apps.apple.com/us/app/stop-political-spam-texts/id6782703267

App name in Connect: **Stop Political Spam Texts**

## What's New (v1.3)

Clearer setup so you can tell it's actually on. A new "Still getting texts?" check tells you whether a message that got through is a setup issue or a rule gap, the home screen now leads with the one step that matters (selecting it in iOS Settings), and we spelled out what to expect: it filters unknown senders only and sorts them to Junk rather than blocking them.

> Paste into App Store Connect when submitting the next build. Remember to bump
> `MARKETING_VERSION` (project.yml) and `CURRENT_PROJECT_VERSION` for the build.

## What's New (v1.2)

Stronger filtering against obfuscated political spam. Refreshed look with a cleaner setup flow, updated app icon, and small usability improvements throughout.

> Paste into App Store Connect when submitting build 4. Current marketing version: **1.2**.

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
2. Open Settings, then go to Apps > Messages and scroll to the Unknown Senders section. (On older iOS: Settings > Messages > Unknown & Spam.)
3. Tap Text Message Filter.
4. Choose Stop Political Spam Texts as the SMS filter. (In the list it may appear as Stop Political Spam.)
5. Return to the app, open Home > Verify Filter, and tap Run verification.

Expected: all built-in samples pass (16/16) with default settings (Filter on, Aggressive strictness, all categories on). Political samples show Outcome: Filtered → Junk; commerce/2FA samples show Allowed → Inbox.

Optional single-message check: Home > Test a Message, paste the sample below, tap Classify.

Example test message:
"Election deadline tonight. Donate now to help our campaign win. Reply STOP to opt out."

Expected result in the in-app tester:
Outcome: Filtered. Destination: Junk.

Filtered texts are routed to Junk by iOS. The app does not delete messages.

Maintainer pre-submit check (optional): from the repo root, run `bash scripts/review_demo.sh`.
