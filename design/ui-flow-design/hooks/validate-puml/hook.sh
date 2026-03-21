#!/bin/bash
# PostToolUse Hook: PlantUML バリデーション
# Write / Edit で .puml ファイルが変更された時に自動実行

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Write / Edit 以外は無視
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

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
  echo "WARN: plantuml not found, skipping validation"
  exit 0
fi

ERRORS=""

# 1. 構文チェック
SYNTAX_RESULT=$(plantuml -checkonly "$FILE_PATH" 2>&1) || true
if echo "$SYNTAX_RESULT" | grep -qi "error"; then
  ERRORS="${ERRORS}Syntax error in ${FILE_PATH}\n${SYNTAX_RESULT}\n"
fi

# 2. 実レンダリング検証
TMP_DIR=$(mktemp -d)
plantuml -tpng -o "$TMP_DIR" "$FILE_PATH" 2>&1 || true
PNG_FILE=$(find "$TMP_DIR" -name "*.png" -type f 2>/dev/null | head -1)

if [ -z "$PNG_FILE" ]; then
  ERRORS="${ERRORS}Render failed: no PNG generated for ${FILE_PATH}\n"
elif command -v sips &>/dev/null; then
  IMG_W=$(sips -g pixelWidth "$PNG_FILE" 2>/dev/null | tail -1 | awk '{print $2}')
  IMG_H=$(sips -g pixelHeight "$PNG_FILE" 2>/dev/null | tail -1 | awk '{print $2}')
  if [ -n "$IMG_W" ] && [ -n "$IMG_H" ]; then
    if [ "$IMG_W" -lt 50 ] && [ "$IMG_H" -lt 50 ]; then
      ERRORS="${ERRORS}Suspicious render: ${IMG_W}x${IMG_H}px (possible error image)\n"
    fi
  fi
fi

rm -rf "$TMP_DIR"

# 3. 構造チェック
OPEN=$(grep -c '{' "$FILE_PATH" 2>/dev/null || echo 0)
CLOSE=$(grep -c '}' "$FILE_PATH" 2>/dev/null || echo 0)
if [ "$OPEN" != "$CLOSE" ]; then
  ERRORS="${ERRORS}Brace mismatch: { = ${OPEN}, } = ${CLOSE}\n"
fi

# 4. @startuml / @enduml 対応チェック
START_COUNT=$(grep -c '@start' "$FILE_PATH" 2>/dev/null || echo 0)
END_COUNT=$(grep -c '@end' "$FILE_PATH" 2>/dev/null || echo 0)
if [ "$START_COUNT" != "$END_COUNT" ]; then
  ERRORS="${ERRORS}@start/@end mismatch: start=${START_COUNT}, end=${END_COUNT}\n"
fi

# 結果出力
if [ -n "$ERRORS" ]; then
  echo ""
  echo "PlantUML Validation FAILED: $(basename "$FILE_PATH")"
  echo -e "$ERRORS"
  echo "Fix the issues above before proceeding."
  exit 0
fi

echo "PlantUML OK: $(basename "$FILE_PATH")"
