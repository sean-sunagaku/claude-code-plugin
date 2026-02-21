#!/bin/bash
# preview-screenshots.sh
# スクリーンショット画像を Quick Look でプレビュー表示する
#
# 使い方:
#   ./preview-screenshots.sh <screenshots-dir>
#   ./preview-screenshots.sh ./screenshots
#
# 機能:
#   - 指定ディレクトリ内の PNG/JPG 画像を一覧表示
#   - 各画像のサイズ・アスペクト比を表示
#   - Quick Look で全画像をプレビュー（macOS）
#   - PhoneMockup 推奨サイズとの比率チェック

set -euo pipefail

# --- 引数チェック ---
if [ $# -lt 1 ]; then
  echo "Usage: $0 <screenshots-dir>"
  echo ""
  echo "Examples:"
  echo "  $0 ./screenshots"
  echo "  $0 /path/to/project/screenshots"
  exit 1
fi

SCREENSHOTS_DIR="$1"

if [ ! -d "$SCREENSHOTS_DIR" ]; then
  echo "Error: Directory not found: $SCREENSHOTS_DIR"
  exit 1
fi

# --- 画像ファイル一覧 ---
echo "=== Screenshot Preview ==="
echo "Directory: $SCREENSHOTS_DIR"
echo ""

IMAGE_FILES=()
while IFS= read -r -d '' file; do
  IMAGE_FILES+=("$file")
done < <(find "$SCREENSHOTS_DIR" -maxdepth 1 \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -print0 | sort -z)

if [ ${#IMAGE_FILES[@]} -eq 0 ]; then
  echo "No PNG/JPG images found in $SCREENSHOTS_DIR"
  exit 1
fi

echo "Found ${#IMAGE_FILES[@]} images:"
echo ""

# --- 各画像の情報表示 ---
printf "%-30s %12s %10s %s\n" "File" "Size (px)" "Ratio" "Status"
printf "%-30s %12s %10s %s\n" "----" "---------" "-----" "------"

RECOMMENDED_RATIO=0.50
TOLERANCE=0.03

for img in "${IMAGE_FILES[@]}"; do
  filename=$(basename "$img")
  width=$(sips -g pixelWidth "$img" 2>/dev/null | tail -1 | awk '{print $2}')
  height=$(sips -g pixelHeight "$img" 2>/dev/null | tail -1 | awk '{print $2}')

  if [ -n "$width" ] && [ -n "$height" ] && [ "$height" -gt 0 ]; then
    ratio=$(echo "scale=3; $width / $height" | bc)
    diff=$(echo "scale=3; $ratio - $RECOMMENDED_RATIO" | bc)
    abs_diff=$(echo "${diff#-}")

    if (( $(echo "$abs_diff < $TOLERANCE" | bc -l) )); then
      status="OK"
    else
      status="WARN (ratio $ratio != $RECOMMENDED_RATIO)"
    fi

    printf "%-30s %5d×%-5d %10s %s\n" "$filename" "$width" "$height" "$ratio" "$status"
  else
    printf "%-30s %12s %10s %s\n" "$filename" "?" "?" "ERROR: cannot read"
  fi
done

echo ""
echo "Recommended PhoneMockup: 320×640 (ratio $RECOMMENDED_RATIO)"
echo ""

# --- Quick Look プレビュー（macOS のみ） ---
if command -v qlmanage &>/dev/null; then
  echo "Opening Quick Look preview..."
  qlmanage -p "${IMAGE_FILES[@]}" &>/dev/null &
  echo "Press Space to navigate, Q to quit Quick Look."
else
  echo "Quick Look not available (non-macOS). Images listed above."
  echo "Open manually: open ${IMAGE_FILES[0]}"
fi
