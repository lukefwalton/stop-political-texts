#!/usr/bin/env bash
# Capture App Store screenshots for Stop Political Spam Texts (iPhone 6.5" + iPad 12.9").
set -euo pipefail
cd "$(dirname "$0")/.."

bash scripts/generate.sh

BUNDLE="com.lukewalton.stoppoliticalspamtexts"
OUT_ROOT="build/app-store-screenshots"

# Resolve a simulator UDID by exact name, then prefix match. Override with IPHONE_SIM_ID / IPAD_SIM_ID.
resolve_sim_id() {
  local -a candidates=("$@")
  xcrun simctl list devices available --json \
    | python3 -c "
import json, sys

candidates = sys.argv[1:]
data = json.load(sys.stdin)
devices = [d for group in data.get('devices', {}).values() for d in group if d.get('isAvailable')]

for name in candidates:
    for d in devices:
        if d['name'] == name:
            print(d['udid'])
            raise SystemExit(0)

for name in candidates:
    for d in devices:
        if d['name'].startswith(name):
            print(d['udid'])
            raise SystemExit(0)

print('No matching simulator. Tried: ' + ', '.join(candidates), file=sys.stderr)
print('Install an iOS runtime with one of those devices, or set IPHONE_SIM_ID / IPAD_SIM_ID.', file=sys.stderr)
raise SystemExit(1)
" "${candidates[@]}"
}

IPHONE_SIM_ID="${IPHONE_SIM_ID:-$(resolve_sim_id "iPhone 15 Plus" "iPhone 14 Plus" "iPhone 15 Pro Max")}"
IPAD_SIM_ID="${IPAD_SIM_ID:-$(resolve_sim_id "iPad Pro (12.9-inch) (6th generation)" "iPad Pro 12.9-inch (6th generation)")}"

flatten_png() {
  local src="$1" dest="$2" height="$3" width="$4"
  local tmp="${dest%.png}.jpg"
  sips -s format jpeg -s formatOptions 100 "$src" --out "$tmp" >/dev/null
  sips -s format png "$tmp" --out "$dest" >/dev/null
  rm -f "$tmp"
  if [[ "$height" != "0" && "$width" != "0" ]]; then
    sips -z "$height" "$width" "$dest" --out "$dest" >/dev/null
  fi
}

wait_for_app_ready() {
  local sim_id="$1"
  local max_attempts="${2:-180}"
  local attempt=0

  while (( attempt < max_attempts )); do
    if [[ "$(xcrun simctl spawn "$sim_id" defaults read "$BUNDLE" ScreenshotReady 2>/dev/null || echo 0)" == "1" ]]; then
      return 0
    fi
    sleep 0.25
    (( attempt++ )) || true
  done

  echo "Timed out waiting for screenshot-ready signal" >&2
  return 1
}

capture_suite() {
  local label="$1"
  local sim_id="$2"
  local out_dir="$3"
  local flat_h="$4"
  local flat_w="$5"

  mkdir -p "$out_dir"

  echo ""
  echo "=== $label ($sim_id) ==="
  echo "Building for simulator..."
  xcodebuild build \
    -scheme StopPoliticalSpamTexts \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$sim_id" \
    -derivedDataPath "build/DerivedData-${label}" \
    CODE_SIGNING_ALLOWED=NO >/dev/null

  local app="build/DerivedData-${label}/Build/Products/Debug-iphonesimulator/StopPoliticalSpamTexts.app"
  xcrun simctl boot "$sim_id" 2>/dev/null || true
  xcrun simctl bootstatus "$sim_id" -b 2>/dev/null || true
  open -a Simulator --args -CurrentDeviceUDID "$sim_id"

  xcrun simctl uninstall "$sim_id" "$BUNDLE" 2>/dev/null || true
  xcrun simctl install "$sim_id" "$app"
  xcrun simctl spawn "$sim_id" defaults write "$BUNDLE" hasCompletedOnboarding -bool true

  capture() {
    local name="$1"
    shift
    echo "Capturing $name..."
    xcrun simctl spawn "$sim_id" defaults delete "$BUNDLE" ScreenshotReady 2>/dev/null || true
    xcrun simctl terminate "$sim_id" "$BUNDLE" 2>/dev/null || true
    xcrun simctl launch "$sim_id" "$BUNDLE" -- "$@" >/dev/null
    wait_for_app_ready "$sim_id"
    local raw="/tmp/spt-${label}-${name}-raw.png"
    xcrun simctl io "$sim_id" screenshot "$raw"
    flatten_png "$raw" "$out_dir/${name}.png" "$flat_h" "$flat_w"
    rm -f "$raw"
    local w h a
    w=$(sips -g pixelWidth "$out_dir/${name}.png" | awk '/pixelWidth/{print $2}')
    h=$(sips -g pixelHeight "$out_dir/${name}.png" | awk '/pixelHeight/{print $2}')
    a=$(sips -g hasAlpha "$out_dir/${name}.png" | awk '/hasAlpha/{print $2}')
    echo "  → $out_dir/${name}.png (${w}x${h}, alpha=$a)"
  }

  capture "01-home"
  capture "02-verify-filter" -OpenVerifyFilter
  capture "03-test-message" -OpenTestMessage
  capture "04-categories" -OpenCategories
}

# iPhone 6.5" → 1284×2778 portrait
capture_suite "iphone" "$IPHONE_SIM_ID" "$OUT_ROOT/iphone" 2778 1284

# iPad 12.9" → 2048×2732 portrait (native sim size; no resize)
capture_suite "ipad" "$IPAD_SIM_ID" "$OUT_ROOT/ipad" 0 0

echo ""
echo "Done → $OUT_ROOT/"
echo "  iPhone 6.5\" → $OUT_ROOT/iphone/"
echo "  iPad 12.9\"  → $OUT_ROOT/ipad/"
open "$OUT_ROOT"
