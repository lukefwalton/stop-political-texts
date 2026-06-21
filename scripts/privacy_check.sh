#!/usr/bin/env bash
#
# Enforces the extension privacy doctrine: the Message Filter Extension must
# make no network calls and must never log message content. Matches code usage
# (call sites / imports), not the doc comments that *describe* the doctrine.
#
# Scans every source directory that ships *inside* the extension target. The
# extension compiles its own sources plus the shared Classifier and Storage
# modules (see project.yml targets.StopPoliticalSpamTextsMessageFilter.sources),
# so a stray URLSession/print/Sentry in any of those would also land on device.
#
# Exits non-zero if any forbidden pattern is found in any scanned directory.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Mirror the extension target's `sources:` list in project.yml. Update both
# together if the extension ever takes on more shared code.
EXT_SOURCE_DIRS=(
  "$ROOT/StopPoliticalSpamTextsMessageFilter"
  "$ROOT/StopPoliticalSpamTexts/Classifier"
  "$ROOT/StopPoliticalSpamTexts/Storage"
)

for dir in "${EXT_SOURCE_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    echo "❌ Privacy check misconfigured: missing source dir $dir"
    echo "   Update EXT_SOURCE_DIRS in scripts/privacy_check.sh to match project.yml."
    exit 1
  fi
done

# Verify EXT_SOURCE_DIRS matches the sources project.yml actually wires into
# the extension target. Without this, a future commit that adds a new shared
# source dir to project.yml (but forgets this script) would quietly reopen the
# privacy coverage gap. The awk extracts `- path:` entries scoped to the
# `StopPoliticalSpamTextsMessageFilter:` target's `sources:` block.
declared=$(awk '
  /^  StopPoliticalSpamTextsMessageFilter:$/ { in_target = 1; next }
  in_target && /^  [A-Za-z]+:$/             { in_target = 0; in_sources = 0 }
  in_target && /^    sources:$/              { in_sources = 1; next }
  in_target && in_sources && /^    [A-Za-z]/ { in_sources = 0 }
  in_target && in_sources && /^      - path:/ { print $3 }
' "$ROOT/project.yml" | sort)

configured=$(printf '%s\n' "${EXT_SOURCE_DIRS[@]}" | sed "s|^$ROOT/||" | sort)

if [[ "$declared" != "$configured" ]]; then
  echo "❌ EXT_SOURCE_DIRS in scripts/privacy_check.sh is out of sync with project.yml"
  echo "   project.yml extension target compiles:"
  printf '%s\n' "$declared" | sed 's/^/      /'
  echo "   scripts/privacy_check.sh scans:"
  printf '%s\n' "$configured" | sed 's/^/      /'
  echo "   Bring them back into alignment so the privacy check covers every"
  echo "   source dir that actually ships in the extension."
  exit 1
fi

# Each entry is an extended-regex matching real usage rather than prose.
PATTERNS=(
  'import +Sentry'
  'import +[A-Za-z]*Analytics'
  'import +(Firebase|Amplitude|Mixpanel|Segment|GoogleAnalytics)'
  'URLSession[[:space:]]*[(.]'
  'deferQueryRequestToNetwork[[:space:]]*\('
  '\.deferQueryRequestToNetwork'
  'NSLog[[:space:]]*\('
  'print[[:space:]]*\('
)

failed=0
for pattern in "${PATTERNS[@]}"; do
  if matches="$(grep -rnE "$pattern" "${EXT_SOURCE_DIRS[@]}" --include='*.swift' 2>/dev/null)"; then
    echo "❌ Forbidden pattern in extension-bound source: /$pattern/"
    echo "$matches"
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo
  echo "Privacy doctrine violated. See PRIVACY.md."
  exit 1
fi

echo "✅ Extension privacy check passed across:"
for dir in "${EXT_SOURCE_DIRS[@]}"; do
  echo "   - ${dir#$ROOT/}"
done
