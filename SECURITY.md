# Security Policy

Stop Political Spam Texts is a local-first iOS app. The message-filter extension
makes **no network calls, imports no analytics or crash SDKs, and persists
nothing** — iOS hands it unknown-sender messages, it returns `.junk` or `.none`,
and it forgets everything. Only user preferences are stored, in the App Group
the app and extension share. That removes whole classes of vulnerability: there
is no server to breach, no data in transit, and no message content at rest. The
app, the filter extension, and the build/release scripts can still have bugs
worth reporting privately.

## Reporting a vulnerability

Please **do not open a public issue** for a security problem. Instead:

1. Email **[luke@lukefwalton.com](mailto:luke@lukefwalton.com)** with a
   description of the issue.
2. Include steps to reproduce, the affected area (app, message-filter extension,
   or a script), and the potential impact.
3. You'll get an acknowledgement within a few days. Please allow a reasonable
   window to ship a fix before disclosing publicly.

## In scope

- Any path that causes the app or extension to make an unexpected network
  request, or to persist message content, senders, or normalized text
- On-device data exposure through the shared App Group store
- Issues in the build/release scripts (`scripts/`) that could compromise a
  release archive or leak signing material

## Not a security issue

- A message that should have been filtered but wasn't (false negative), or one
  that was filtered but shouldn't have been (false positive) — those are
  classifier tuning. Please use
  [GitHub Issues](https://github.com/lukefwalton/stop-political-texts/issues).
- Feature requests or visual/UI bugs with no security impact.

## Supported versions

Fixes target the latest App Store release and the `main` branch. Older builds
are not separately patched.
