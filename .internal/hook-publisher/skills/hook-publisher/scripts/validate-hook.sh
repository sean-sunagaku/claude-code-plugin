#!/bin/bash
# validate-hook.sh - Hook スクリプトの構造を検証する
#
# Usage: validate-hook.sh <hook-path> [plugin-json-path]
#   hook-path:        hook.py (or hook.sh) があるディレクトリ
#   plugin-json-path: (optional) plugin.json のパス。指定時は command パスも検証

set -euo pipefail

HOOK_PATH="${1:?Usage: validate-hook.sh <hook-path> [plugin-json-path]}"
PLUGIN_JSON="${2:-}"
ERRORS=0
WARNINGS=0

echo "=== Validating hook: $HOOK_PATH ==="
echo ""

# 1. hook スクリプトの存在確認
if [ -f "$HOOK_PATH/hook.py" ]; then
  echo "  OK hook.py found"
  HOOK_FILE="hook.py"
  HOOK_LANG="python"
elif [ -f "$HOOK_PATH/hook.sh" ]; then
  echo "  OK hook.sh found"
  HOOK_FILE="hook.sh"
  HOOK_LANG="bash"
else
  echo "  NG hook.py or hook.sh not found"
  ((ERRORS++))
  HOOK_LANG=""
fi

# 2. テストの存在確認
if [ -f "$HOOK_PATH/test.py" ]; then
  echo "  OK test.py found"
elif [ -f "$HOOK_PATH/test.sh" ]; then
  echo "  OK test.sh found"
else
  echo "  WARN test file not found (recommended: test.py or test.sh)"
  ((WARNINGS++))
fi

# 3. 構文チェック
if [ "$HOOK_LANG" = "python" ]; then
  if python3 -c "import py_compile; py_compile.compile('$HOOK_PATH/hook.py', doraise=True)" 2>/dev/null; then
    echo "  OK hook.py syntax OK"
  else
    echo "  NG hook.py has syntax errors"
    ((ERRORS++))
  fi
elif [ "$HOOK_LANG" = "bash" ]; then
  if bash -n "$HOOK_PATH/hook.sh" 2>/dev/null; then
    echo "  OK hook.sh syntax OK"
  else
    echo "  NG hook.sh has syntax errors"
    ((ERRORS++))
  fi
fi

# 4. plugin.json の command パス検証（指定時のみ）
if [ -n "$PLUGIN_JSON" ] && [ -f "$PLUGIN_JSON" ]; then
  echo ""
  echo "=== Validating plugin.json: $PLUGIN_JSON ==="
  echo ""

  if command -v jq &> /dev/null; then
    # command フィールドを全て抽出
    COMMANDS=$(jq -r '.. | .command? // empty' "$PLUGIN_JSON" 2>/dev/null)

    if [ -z "$COMMANDS" ]; then
      echo "  WARN no command found in plugin.json"
      ((WARNINGS++))
    else
      while IFS= read -r cmd; do
        # $HOME ベースのポータブルパスかチェック
        if echo "$cmd" | grep -q '\$HOME/.claude/plugins/cache/'; then
          echo "  OK portable path: $cmd"
        elif echo "$cmd" | grep -q '\.claude/hooks/'; then
          echo "  NG project-local path (not portable): $cmd"
          echo "     -> Use \$HOME/.claude/plugins/cache/<marketplace>/<plugin>/<version>/hooks/... instead"
          ((ERRORS++))
        elif echo "$cmd" | grep -q '/Users/'; then
          echo "  NG hardcoded user path (not portable): $cmd"
          echo "     -> Use \$HOME instead of /Users/<username>"
          ((ERRORS++))
        else
          echo "  WARN unrecognized command pattern: $cmd"
          ((WARNINGS++))
        fi
      done <<< "$COMMANDS"
    fi
  else
    echo "  WARN jq not available, skipping plugin.json validation"
    ((WARNINGS++))
  fi
fi

# 結果
echo ""
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo "Validation passed"
  exit 0
elif [ "$ERRORS" -eq 0 ]; then
  echo "Validation passed with $WARNINGS warning(s)"
  exit 0
else
  echo "Validation failed: $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
fi
