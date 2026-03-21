#!/bin/bash
# PostToolUse Hook: marketplace 構造バリデーション
# plugin repo 内のファイルが Write/Edit された時に自動検証
#
# matcher: "Edit|Write"
# 対象: marketplace.json, plugin.json, SKILL.md, agents/*.md が変更された場合のみ実行

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# plugin repo 内のファイルか判定
PLUGIN_REPO="/Users/babashunsuke/Repository/claude-code-plugin"
case "$FILE_PATH" in
  "$PLUGIN_REPO"*) ;;
  *) exit 0 ;;
esac

# 検証対象のファイルパターンに一致するか
FILENAME=$(basename "$FILE_PATH")
case "$FILENAME" in
  marketplace.json|plugin.json|SKILL.md) ;;
  *.md)
    # agents/ 配下の .md のみ対象
    case "$FILE_PATH" in
      */agents/*) ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac

# バリデーションスクリプトの存在確認
VALIDATE_SCRIPT="$PLUGIN_REPO/.github/scripts/validate-marketplace.sh"
if [ ! -f "$VALIDATE_SCRIPT" ]; then
  exit 0
fi

# バリデーション実行
RESULT=$(bash "$VALIDATE_SCRIPT" 2>&1)
ERRORS=$(echo "$RESULT" | grep -oP 'Errors:\s+\K\d+' || echo "0")
FINAL=$(echo "$RESULT" | tail -1)

if [ "$FINAL" = "FAILED" ]; then
  # エラー行だけ抽出して表示
  echo ""
  echo "Marketplace Validation FAILED after editing: $FILENAME"
  echo "$RESULT" | grep "^ERROR:" | head -10
  echo ""
  echo "Run: bash .github/scripts/validate-marketplace.sh for full output"
else
  echo ""
  echo "Marketplace Validation PASSED ($FILENAME)"
fi

exit 0
