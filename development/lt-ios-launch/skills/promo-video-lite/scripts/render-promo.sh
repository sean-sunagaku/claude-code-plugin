#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <play.png> <result.png> <output.mp4>" >&2
  exit 64
fi

play_path="$1"
result_path="$2"
output_path="$3"

for input_path in "$play_path" "$result_path"; do
  if [[ ! -s "$input_path" ]]; then
    echo "Input image does not exist or is empty: $input_path" >&2
    exit 66
  fi
done

for command_name in magick ffmpeg ffprobe; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 69
  fi
done

font_path="/System/Library/Fonts/Hiragino Sans GB.ttc"
if [[ ! -f "$font_path" ]]; then
  font_path="/Library/Fonts/SF-Pro.ttf"
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/irochigai-promo.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

make_beat() {
  local screenshot_path="$1"
  local caption="$2"
  local detail="$3"
  local destination="$4"

  magick \
    -size 1080x1920 gradient:'#F8FAF7-#DDE9E2' \
    \( "$screenshot_path" -auto-orient -resize '790x1420>' \
      -bordercolor '#1C2520' -border 9 \) \
    -gravity south -geometry +0+105 -composite \
    -font "$font_path" -fill '#14221B' \
    -gravity north -pointsize 69 -annotate +0+105 "$caption" \
    -fill '#43544B' -pointsize 36 -annotate +0+205 "$detail" \
    -strip "$destination"
}

make_beat "$play_path" '1マスだけ、違う。' '静かな30秒チャレンジ' "$work_dir/beat-1.png"
make_beat "$play_path" 'あなたは見つけられる？' 'タップするほど、少しずつ難しく' "$work_dir/beat-2.png"
make_beat "$result_path" 'いろちがい' '通信なし・アカウント不要' "$work_dir/beat-3.png"

mkdir -p "$(dirname "$output_path")"

ffmpeg -hide_banner -loglevel error -y \
  -loop 1 -t 5 -i "$work_dir/beat-1.png" \
  -loop 1 -t 5 -i "$work_dir/beat-2.png" \
  -loop 1 -t 5 -i "$work_dir/beat-3.png" \
  -filter_complex \
  '[0:v]fps=30,format=yuv420p[v0];[1:v]fps=30,format=yuv420p[v1];[2:v]fps=30,format=yuv420p[v2];[v0][v1][v2]concat=n=3:v=1:a=0[outv]' \
  -map '[outv]' -c:v libx264 -preset medium -crf 20 -movflags +faststart \
  "$output_path"

probe="$(
  ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=codec_name,width,height,pix_fmt \
    -show_entries format=duration \
    -of default=noprint_wrappers=1 "$output_path"
)"

echo "Rendered promo video: $output_path"
echo "$probe"
