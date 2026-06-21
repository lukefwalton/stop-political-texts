#!/usr/bin/env bash
#
# Runs the built-in classifier verification corpus and prints a human-readable
# report. Use before App Store submission; point App Review to the in-app
# Home > Verify Filter screen for on-device verification.
#
# Requires: Xcode, xcodegen, an iOS Simulator.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "❌ xcodegen not found. Install with: brew install xcodegen"
  exit 1
fi

xcodegen generate >/dev/null

DEST='platform=iOS Simulator,name=iPhone 17'
if ! xcrun simctl list devices available | grep -q "iPhone 17 ("; then
  UDID=$(xcrun simctl list devices available --json \
    | python3 -c "import json,sys; r=json.load(sys.stdin)['devices']; ids=[d['udid'] for ds in r.values() for d in ds if d['name'].startswith('iPhone')]; print(ids[0] if ids else '')")
  if [[ -z "$UDID" ]]; then
    echo "❌ No iPhone simulator available"
    exit 1
  fi
  DEST="id=$UDID"
fi

echo "Running classifier fixture tests on: $DEST"
echo

LOG="$(mktemp)"
set +e
xcodebuild test \
  -scheme StopPoliticalSpamTexts \
  -destination "$DEST" \
  -only-testing:StopPoliticalSpamTextsTests/ClassifierFixturesTests \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  EXCLUDED_ARCHS=x86_64 \
  >"$LOG" 2>&1
STATUS=$?
set -e

if grep -q "Test Suite 'All tests' passed" "$LOG"; then
  echo "✅ Classifier verification passed"
  echo
  echo "Sample corpus:"
  python3 - <<'PY'
import pathlib, re
text = pathlib.Path("StopPoliticalSpamTexts/Classifier/ClassifierFixtures.swift").read_text()
labels = re.findall(r'label: "([^"]+)"', text)
for i, label in enumerate(labels[:8], 1):
    print(f"  {i}. {label}")
if len(labels) > 8:
    print(f"  … and {len(labels) - 8} more")
PY
  echo
  echo "For App Review: install the app → Home → Verify Filter → Run verification."
  echo "Expected: all samples pass with default settings (Aggressive, filter on)."
else
  echo "❌ Classifier verification failed"
  echo
  grep -E "error:|failed|FAIL" "$LOG" | tail -20 || tail -30 "$LOG"
fi

rm -f "$LOG"
exit "$STATUS"
