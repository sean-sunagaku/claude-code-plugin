#!/bin/bash
# export-screenshots.sh
# Pencil export_nodes 後のノードIDファイルをフレーム名にリネームし、
# 言語別フォルダに整理し、App Store 要求サイズを検証する。
#
# 使い方:
#   ./export-screenshots.sh <export-dir> <output-dir> <id:name> [<id:name> ...]
#
# 例:
#   ./export-screenshots.sh /tmp/pencil-export ./exported \
#     b4SOM:SS01_Hero dBSNw:SS03_Result SM4Ui:SS04_Template \
#     dhs8L:SS01_Hero_EN WG7lQ:SS03_Result_EN eE2yT:SS04_Template_EN
#
# 動作:
#   1. ノードID.png → フレーム名.png にリネーム
#   2. 言語サフィックス (_EN, _ZH, _KO) で言語フォルダに振り分け
#      - サフィックスなし → JP/
#      - _EN → EN/、_ZH → ZH/、_KO → KO/
#   3. 全ファイルの寸法を sips で検証（App Store 要求サイズと照合）
#   4. サマリーレポートを表示
#
# App Store 要求サイズ（いずれか）:
#   - 1242 × 2688 px (iPhone XS Max)
#   - 1284 × 2778 px (iPhone 6.5")
#   - 1290 × 2796 px (iPhone 6.7")
#   - 1320 × 2868 px (iPhone 6.9")

set -euo pipefail

# --- 引数チェック ---
if [ $# -lt 3 ]; then
  echo "Usage: $0 <export-dir> <output-dir> <id:name> [<id:name> ...]"
  echo ""
  echo "Example:"
  echo "  $0 /tmp/pencil-export ./exported b4SOM:SS01_Hero dhs8L:SS01_Hero_EN"
  exit 1
fi

EXPORT_DIR="$1"
OUTPUT_DIR="$2"
shift 2

if [ ! -d "$EXPORT_DIR" ]; then
  echo "Error: Export directory not found: $EXPORT_DIR"
  exit 1
fi

# --- App Store 許容サイズ ---
VALID_SIZES=(
  "1242x2688"
  "2688x1242"
  "1284x2778"
  "2778x1284"
  "1290x2796"
  "2796x1290"
  "1320x2868"
  "2868x1320"
)

is_valid_size() {
  local size="$1"
  for valid in "${VALID_SIZES[@]}"; do
    if [ "$size" = "$valid" ]; then
      return 0
    fi
  done
  return 1
}

# --- 言語フォルダの判定 ---
get_lang_folder() {
  local name="$1"
  if [[ "$name" == *_EN ]]; then
    echo "EN"
  elif [[ "$name" == *_ZH ]]; then
    echo "ZH"
  elif [[ "$name" == *_KO ]]; then
    echo "KO"
  else
    echo "JP"
  fi
}

# --- ファイル名から言語サフィックスを除去 ---
strip_lang_suffix() {
  local name="$1"
  name="${name%_EN}"
  name="${name%_ZH}"
  name="${name%_KO}"
  echo "$name"
}

# --- メイン処理 ---
echo "=== Screenshot Export & Rename ==="
echo "Source:  $EXPORT_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

# 出力フォルダ作成
mkdir -p "$OUTPUT_DIR"/{JP,EN,ZH,KO}

TOTAL=0
PASS=0
FAIL=0
MISSING=0

printf "%-20s → %-6s %-24s %14s %s\n" "NodeID" "Lang" "FileName" "Size" "Status"
printf "%-20s   %-6s %-24s %14s %s\n" "------" "----" "--------" "----" "------"

for mapping in "$@"; do
  # id:name のパース
  IFS=':' read -r node_id frame_name <<< "$mapping"

  if [ -z "$node_id" ] || [ -z "$frame_name" ]; then
    echo "Warning: Invalid mapping '$mapping' (expected id:name)"
    continue
  fi

  TOTAL=$((TOTAL + 1))
  src="$EXPORT_DIR/$node_id.png"

  # 言語フォルダとファイル名を決定
  lang=$(get_lang_folder "$frame_name")
  clean_name=$(strip_lang_suffix "$frame_name")
  dst="$OUTPUT_DIR/$lang/$clean_name.png"

  if [ ! -f "$src" ]; then
    printf "%-20s → %-6s %-24s %14s %s\n" "$node_id" "$lang" "$clean_name.png" "-" "MISSING"
    MISSING=$((MISSING + 1))
    continue
  fi

  # コピー（元ファイルは残す）
  cp "$src" "$dst"

  # サイズ検証
  width=$(sips -g pixelWidth "$dst" 2>/dev/null | tail -1 | awk '{print $2}')
  height=$(sips -g pixelHeight "$dst" 2>/dev/null | tail -1 | awk '{print $2}')
  size="${width}x${height}"

  if is_valid_size "$size"; then
    status="PASS"
    PASS=$((PASS + 1))
  else
    status="FAIL (expected 1284x2778 etc.)"
    FAIL=$((FAIL + 1))
  fi

  printf "%-20s → %-6s %-24s %14s %s\n" "$node_id" "$lang" "$clean_name.png" "${width}×${height}" "$status"
done

# --- サマリー ---
echo ""
echo "=== Summary ==="
echo "Total: $TOTAL | Pass: $PASS | Fail: $FAIL | Missing: $MISSING"
echo ""

# 出力フォルダの中身を表示
for lang in JP EN ZH KO; do
  count=$(find "$OUTPUT_DIR/$lang" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    echo "$lang/ ($count files):"
    ls -1 "$OUTPUT_DIR/$lang/"*.png 2>/dev/null | while read -r f; do
      echo "  $(basename "$f")"
    done
  fi
done

echo ""
if [ "$FAIL" -gt 0 ] || [ "$MISSING" -gt 0 ]; then
  echo "WARNING: Some files failed validation. Check sizes and re-export with scale: 3."
  exit 1
else
  echo "All screenshots exported and validated successfully."
  exit 0
fi
