#!/bin/bash
# PostToolUse Hook: PlantUML バリデーション
# Write / Edit で .puml ファイルが変更された時に自動実行
#
# matcher: "Edit|Write"
# 入力: stdin から JSON (tool_input.file_path)
# 出力: stdout にバリデーション結果

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# .puml ファイル以外は無視
case "$FILE_PATH" in
  *.puml) ;;
  *) exit 0 ;;
esac

# ファイルが存在するか確認
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# plantuml がインストールされているか確認
if ! command -v plantuml &>/dev/null; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")
ERRORS=""

# 1. @startuml / @enduml の対応チェック
START_COUNT=$(grep -c '@startuml' "$FILE_PATH" 2>/dev/null || echo 0)
END_COUNT=$(grep -c '@enduml' "$FILE_PATH" 2>/dev/null || echo 0)
if [ "$START_COUNT" != "$END_COUNT" ]; then
  ERRORS="${ERRORS}- @startuml/@enduml mismatch: start=${START_COUNT}, end=${END_COUNT}\n"
fi

# 2. 波括弧の対応チェック
OPEN=$(grep -c '{' "$FILE_PATH" 2>/dev/null || echo 0)
CLOSE=$(grep -c '}' "$FILE_PATH" 2>/dev/null || echo 0)
if [ "$OPEN" != "$CLOSE" ]; then
  ERRORS="${ERRORS}- Brace mismatch: { = ${OPEN}, } = ${CLOSE}\n"
fi

# 3. 実レンダリング検証（構文エラーの確実な検出）
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

plantuml -tpng -o "$TMP_DIR" "$FILE_PATH" 2>&1 || true
PNG_FILE=$(find "$TMP_DIR" -name "*.png" -type f 2>/dev/null | head -1)

if [ -z "$PNG_FILE" ]; then
  ERRORS="${ERRORS}- Render failed: no PNG generated\n"
elif command -v sips &>/dev/null; then
  IMG_W=$(sips -g pixelWidth "$PNG_FILE" 2>/dev/null | tail -1 | awk '{print $2}')
  IMG_H=$(sips -g pixelHeight "$PNG_FILE" 2>/dev/null | tail -1 | awk '{print $2}')
  if [ -n "$IMG_W" ] && [ -n "$IMG_H" ]; then
    if [ "$IMG_W" -lt 50 ] && [ "$IMG_H" -lt 50 ]; then
      ERRORS="${ERRORS}- Suspicious render: ${IMG_W}x${IMG_H}px (possible error image)\n"
    fi
  fi
fi

# 結果出力
if [ -n "$ERRORS" ]; then
  echo ""
  echo "PlantUML Validation FAILED: ${FILENAME}"
  echo -e "$ERRORS"
  echo "Fix the issues above before proceeding."
else
  echo ""
  echo "PlantUML OK: ${FILENAME}"
fi

exit 0
