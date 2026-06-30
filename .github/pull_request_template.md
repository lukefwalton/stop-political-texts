## What & why

<!-- What does this change do, and why? Link any related issue (e.g. Closes #12). -->

## Checklist

- [ ] CI passes (iOS tests + the extension privacy check)
- [ ] Tests added or updated for new logic, where it applies (classifier,
      normalizer, URL extractor, sender analyzer, config migration)
- [ ] `bash scripts/privacy_check.sh` still passes (no network, no analytics, no
      message-content persistence in the extension)
- [ ] Docs updated if behavior or setup changed
