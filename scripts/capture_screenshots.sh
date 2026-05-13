#!/usr/bin/env bash
set -euo pipefail

package_name="com.dupuyfrancoise.operations"
screens_dir="docs/screens"

device_size="$(adb shell wm size | tr -d '\r' | sed -nE 's/.*Physical size: ([0-9]+)x([0-9]+).*/\1 \2/p' | head -n 1)"
if [[ -z "${device_size}" ]]; then
  echo "Unable to read device size from adb." >&2
  exit 1
fi

read -r width height <<<"${device_size}"
nav_y=$((height - 260))
queue_x=$((width * 3 / 10))
new_x=$((width * 5 / 10))
reports_x=$((width * 7 / 10))
privacy_x=$((width * 9 / 10))
detail_y=$((height / 4))

mkdir -p "${screens_dir}"
find "${screens_dir}" -maxdepth 1 -type f -name '*.png' -delete
touch "${screens_dir}/.gitkeep"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  flutter build apk --debug --dart-define=SCREENSHOT_MODE=true
fi

if [[ ! -f build/app/outputs/flutter-apk/app-debug.apk ]]; then
  echo "Missing build/app/outputs/flutter-apk/app-debug.apk." >&2
  exit 1
fi

adb install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
adb shell am force-stop "${package_name}" >/dev/null 2>&1 || true
adb shell monkey -p "${package_name}" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 7

capture() {
  local name="$1"
  local foreground

  foreground="$(adb shell dumpsys window | tr -d '\r' | sed -nE 's/.*mCurrentFocus=.* ([^ ]+)\/.*/\1/p' | tail -n 1)"
  if [[ "${foreground}" != "${package_name}" ]]; then
    echo "Refusing screenshot ${name}; foreground package is ${foreground:-unknown}." >&2
    exit 1
  fi

  adb exec-out screencap -p > "${screens_dir}/${name}.png"
}

capture "01_dashboard"
adb shell input tap "${queue_x}" "${nav_y}"
sleep 2
capture "02_queue"
adb shell input tap "$((width / 2))" "${detail_y}"
sleep 2
capture "03_detail"
adb shell input keyevent KEYCODE_BACK
sleep 1
adb shell input tap "${new_x}" "${nav_y}"
sleep 2
capture "04_create"
adb shell input tap "${reports_x}" "${nav_y}"
sleep 2
capture "05_reports"
adb shell input tap "${privacy_x}" "${nav_y}"
sleep 2
capture "06_privacy"

printf 'Captured screenshots in %s\n' "${screens_dir}"
