#!/usr/bin/env bash
#
# check_designsystem_sync.sh — CI drift guard for the vendored LFWDesignSystem.
#
# The design system is copied into every app repo (see scripts/sync_designsystem.sh).
# This guard recomputes a checksum of the vendored package and compares it to the
# committed lfwdesignsystem/CHECKSUMS.txt. It is an ACCIDENTAL-DRIFT guard: it
# fails on a hand-edit to the vendored copy that doesn't also regenerate the
# manifest. It does NOT prove the copy matches the canonical upstream — a
# deliberate edit that regenerates CHECKSUMS.txt in the same commit still passes.
# Canonical parity is enforced by process (edit canonical, run the sync script),
# not by this check.
#
# Self-contained: it does NOT need the other repos present, so it runs on a plain
# Ubuntu CI runner. To legitimately change the design system: edit it in the
# canonical repo (a-new-word-every-day), run sync_designsystem.sh, commit.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DS="$ROOT/lfwdesignsystem"
MANIFEST="$DS/CHECKSUMS.txt"

[ -f "$MANIFEST" ] || { echo "::error::missing $MANIFEST — run scripts/sync_designsystem.sh"; exit 1; }

# Must match sync_designsystem.sh: hash the code/tests/manifest/version only —
# LICENSE and README.md are per-repo and deliberately excluded.
SYNC_ITEMS=(Sources Tests Package.swift VERSION)
if command -v sha256sum >/dev/null 2>&1; then SHA_BIN="sha256sum"; else SHA_BIN="shasum -a 256"; fi

actual="$(cd "$DS" && find "${SYNC_ITEMS[@]}" -type f 2>/dev/null \
  | LC_ALL=C sort | xargs $SHA_BIN)"

if ! diff <(printf '%s\n' "$actual") "$MANIFEST" >/dev/null 2>&1; then
  echo "::error::vendored lfwdesignsystem does not match CHECKSUMS.txt (version $(cat "$DS/VERSION" 2>/dev/null || echo '?'))."
  echo "The vendored design system no longer matches its committed manifest. Edit it"
  echo "in a-new-word-every-day, run scripts/sync_designsystem.sh, commit. Offending files:"
  diff <(printf '%s\n' "$actual") "$MANIFEST" || true
  exit 1
fi

echo "lfwdesignsystem in sync (version $(cat "$DS/VERSION" 2>/dev/null || echo '?'))."
