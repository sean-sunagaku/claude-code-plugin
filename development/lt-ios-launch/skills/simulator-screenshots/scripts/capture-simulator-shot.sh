#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <label> <output-directory>" >&2
  exit 64
fi

label="$1"
output_dir="$2"

if [[ ! "$label" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Label may contain only letters, numbers, underscores, and hyphens." >&2
  exit 64
fi

for command_name in xcrun jq magick; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 69
  fi
done

booted_ids="$(
  xcrun simctl list devices booted --json |
    jq -r '.devices[][] | select(.state == "Booted") | .udid'
)"

if [[ -z "$booted_ids" ]]; then
  echo "No booted iOS Simulator was found." >&2
  exit 69
fi

if [[ -n "${SCREENSHOT_SIMULATOR_UDID:-}" ]]; then
  if ! grep -Fxq "$SCREENSHOT_SIMULATOR_UDID" <<<"$booted_ids"; then
    echo "SCREENSHOT_SIMULATOR_UDID is not a booted Simulator: $SCREENSHOT_SIMULATOR_UDID" >&2
    exit 69
  fi
  device_id="$SCREENSHOT_SIMULATOR_UDID"
else
  device_count="$(wc -l <<<"$booted_ids" | tr -d ' ')"
  if [[ "$device_count" -ne 1 ]]; then
    echo "Multiple iOS Simulators are booted. Set SCREENSHOT_SIMULATOR_UDID explicitly:" >&2
    sed 's/^/  /' <<<"$booted_ids" >&2
    exit 64
  fi
  device_id="$booted_ids"
fi

mkdir -p "$output_dir"
output_path="${output_dir%/}/${label}.png"

xcrun simctl io "$device_id" screenshot "$output_path" >/dev/null

if [[ ! -s "$output_path" ]]; then
  echo "Screenshot was not created: $output_path" >&2
  exit 74
fi

# simctl may emit a fully opaque RGBA PNG. App Store Connect rejects any alpha
# channel even when every alpha value is 1, so normalize the file to 8-bit RGB.
rgb_output_path="${output_path}.rgb.png"
magick "$output_path" \
  -alpha off -colorspace sRGB -define png:color-type=2 -strip \
  "$rgb_output_path"
mv "$rgb_output_path" "$output_path"

dimensions="$(
  sips -g pixelWidth -g pixelHeight "$output_path" 2>/dev/null |
    awk '/pixelWidth:/{width=$2} /pixelHeight:/{height=$2} END{print width "x" height}'
)"

alpha_trait="$(magick identify -format '%A' "$output_path")"
if [[ "$alpha_trait" != "Undefined" ]]; then
  echo "Screenshot still has an alpha channel: $output_path ($alpha_trait)" >&2
  exit 74
fi

echo "Captured ${label}: ${output_path} (${dimensions}, RGB/no alpha, simulator ${device_id})"
