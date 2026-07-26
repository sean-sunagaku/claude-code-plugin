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

for command_name in xcrun jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 69
  fi
done

device_id="$(
  xcrun simctl list devices booted --json |
    jq -r '[.devices[][] | select(.state == "Booted") | .udid][0] // empty'
)"

if [[ -z "$device_id" ]]; then
  echo "No booted iOS Simulator was found." >&2
  exit 69
fi

mkdir -p "$output_dir"
output_path="${output_dir%/}/${label}.png"

xcrun simctl io "$device_id" screenshot "$output_path" >/dev/null

if [[ ! -s "$output_path" ]]; then
  echo "Screenshot was not created: $output_path" >&2
  exit 74
fi

dimensions="$(
  sips -g pixelWidth -g pixelHeight "$output_path" 2>/dev/null |
    awk '/pixelWidth:/{width=$2} /pixelHeight:/{height=$2} END{print width "x" height}'
)"

echo "Captured ${label}: ${output_path} (${dimensions}, simulator ${device_id})"
