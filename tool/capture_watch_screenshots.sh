#!/usr/bin/env bash
#
# Captures App Store screenshots for the watchOS app in a simulator.
#
# The watch app renders whatever the phone last wrote to the shared App Group,
# so this seeds a representative shift schedule first, then opens each page
# directly via the DEBUG-only `screenshot_initial_tab` key (see ScreenshotMode
# in ContentView.swift) — simctl's SIMCTL_CHILD_* env vars do not reach a
# watchOS app, and there is no way to script a swipe.
#
# The app is reinstalled before every capture on purpose: once the app has read
# the shared suite, cfprefsd serves it a cached copy and later `defaults write`
# calls to the container path are ignored.
#
# Usage: tool/capture_watch_screenshots.sh ["<simulator name>"] [<file prefix>]
set -euo pipefail

DEVICE_NAME="${1:-Apple Watch Ultra 3 (49mm)}"
PREFIX="${2:-watch}"
BUNDLE_ID="com.change.app.change.watchkitapp"
GROUP_ID="group.com.change.app.change"
OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/screenshots/watch"

UDID=$(xcrun simctl list devices available \
  | grep -F "$DEVICE_NAME (" \
  | head -1 \
  | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
if [ -z "$UDID" ]; then
  echo "simulator not found: $DEVICE_NAME" >&2
  exit 1
fi
echo "device: $DEVICE_NAME ($UDID)"

echo "building…"
xcodebuild -workspace "$(dirname "$0")/../ios/Runner.xcworkspace" \
  -scheme ChangeWatch \
  -destination "platform=watchOS Simulator,name=$DEVICE_NAME" \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build >/dev/null
APP=$(find ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-watchsimulator \
  -maxdepth 1 -name "ChangeWatch.app" -print0 | xargs -0 ls -td | head -1)

# A shift week with every type represented. Today is whichever shift is
# actually running right now, so the timer page always shows a live countdown
# instead of "종료" — the capture must look the same whatever time it is run.
WEEK_JSON=$(python3 - <<'PY'
import json, datetime
TIMES = {'day': ('06:00', '14:00'), 'evening': ('14:00', '22:00'),
         'night': ('22:00', '06:00'), 'off': ('', '')}
LABEL = {'day': '주간', 'evening': '오후', 'night': '야간', 'off': '휴무'}
hour = datetime.datetime.now().hour
if 6 <= hour < 14:
    today_type = 'day'
elif 14 <= hour < 22:
    today_type = 'evening'
else:
    today_type = 'night'

others = [t for t in ('day', 'evening', 'night') if t != today_type]
# Two days on the current shift, two off, then the other two types — every
# colour shows up in the week strip.
PLAN = [today_type, today_type, 'off', 'off', others[0], others[0], others[1],
        others[1], today_type, today_type, 'off', 'off', others[0], others[0]]

today = datetime.date.today()
print(json.dumps([
    {'date': (today + datetime.timedelta(days=i)).strftime('%Y-%m-%d'),
     'type': t, 'label': LABEL[t], 'start': TIMES[t][0], 'end': TIMES[t][1]}
    for i, t in enumerate(PLAN)
], ensure_ascii=False))
PY
)

TODAY=$(printf '%s' "$WEEK_JSON" | python3 -c "
import json,sys
d = json.load(sys.stdin)[0]
print(d['type'], d['label'], d['start'], d['end'])
")
read -r TODAY_TYPE TODAY_LABEL TODAY_START TODAY_END <<<"$TODAY"
echo "today: $TODAY_LABEL $TODAY_START-$TODAY_END"

xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
xcrun simctl erase "$UDID"
xcrun simctl boot "$UDID"
sleep 18

mkdir -p "$OUT_DIR"
capture() {
  local tab="$1" name="$2"
  xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$UDID" "$APP"

  local container prefs
  container=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)
  prefs="$container/Library/Preferences/$GROUP_ID"
  mkdir -p "$container/Library/Preferences"

  xcrun simctl spawn "$UDID" defaults write "$prefs" screenshot_initial_tab -int "$tab"
  xcrun simctl spawn "$UDID" defaults write "$prefs" widget_week_shifts -string "$WEEK_JSON"
  xcrun simctl spawn "$UDID" defaults write "$prefs" widget_today_shift_type -string "$TODAY_TYPE"
  xcrun simctl spawn "$UDID" defaults write "$prefs" widget_today_shift_label -string "$TODAY_LABEL"
  xcrun simctl spawn "$UDID" defaults write "$prefs" widget_today_shift_start -string "$TODAY_START"
  xcrun simctl spawn "$UDID" defaults write "$prefs" widget_today_shift_end -string "$TODAY_END"
  xcrun simctl spawn "$UDID" defaults write "$prefs" widget_energy_latest -int 4
  xcrun simctl spawn "$UDID" defaults write "$prefs" widget_energy_avg -float 3.8
  xcrun simctl spawn "$UDID" defaults write "$prefs" widget_sleep_hours -float 6.8
  xcrun simctl spawn "$UDID" defaults write "$prefs" widget_sleep_quality -int 4
  # widget_last_updated is left unset on purpose: the simulator renders that
  # relative timestamp in English regardless of the device language.

  xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null
  sleep 6
  xcrun simctl io "$UDID" screenshot --type=png "$OUT_DIR/$PREFIX-$name.png" >/dev/null 2>&1
  echo "  $PREFIX-$name.png"
}

# Tab 2 (건강 요약) is skipped: it renders live HealthKit data, which a
# simulator has none of, so it would only ever show zeros.
capture 0 "01-today-shift"
capture 1 "02-week-schedule"
capture 3 "03-shift-timer"
capture 4 "04-energy-record"

xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
echo "done -> $OUT_DIR"
