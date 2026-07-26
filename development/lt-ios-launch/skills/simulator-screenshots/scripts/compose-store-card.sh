#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <raw.png> <headline> <subheadline> <output.png>" >&2
  exit 64
fi

raw_path="$1"
headline="$2"
subheadline="$3"
output_path="$4"

if [[ ! -s "$raw_path" ]]; then
  echo "Input screenshot does not exist or is empty: $raw_path" >&2
  exit 66
fi

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick 'magick' is required." >&2
  exit 69
fi

font_path="/System/Library/Fonts/Hiragino Sans GB.ttc"
if [[ ! -f "$font_path" ]]; then
  font_path="/Library/Fonts/SF-Pro.ttf"
fi

mkdir -p "$(dirname "$output_path")"

magick \
  -size 1290x2796 gradient:'#F8FAF7-#DDE9E2' \
  \( "$raw_path" -auto-orient -resize '1030x2160>' \
    -bordercolor '#1C2520' -border 12 \
    -alpha set -background none \) \
  -gravity south -geometry +0+110 -composite \
  -font "$font_path" -fill '#14221B' \
  -gravity north -pointsize 82 -annotate +0+105 "$headline" \
  -pointsize 42 -fill '#43544B' -annotate +0+225 "$subheadline" \
  -strip "$output_path"

dimensions="$(
  magick identify -format '%wx%h' "$output_path"
)"

if [[ "$dimensions" != "1290x2796" ]]; then
  echo "Unexpected output dimensions: $dimensions" >&2
  exit 74
fi

echo "Composed App Store card: ${output_path} (${dimensions})"
