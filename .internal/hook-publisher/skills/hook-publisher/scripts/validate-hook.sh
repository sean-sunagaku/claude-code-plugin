#!/bin/bash
# validate-hook.sh - Hook スクリプトの構造を検証する
#
# Usage: validate-hook.sh <hook-path>
#   hook-path: hook.py (or hook.sh) があるディレクトリ

set -euo pipefail

HOOK_PATH="${1:?Usage: validate-hook.sh <hook-path>}"
ERRORS=0

echo "=== Validating hook: $HOOK_PATH ==="
echo ""

# 1. hook スクリプトの存在確認
if [ -f "$HOOK_PATH/hook.py" ]; then
  echo "  ✅ hook.py found"
  HOOK_FILE="hook.py"
  HOOK_LANG="python"
elif [ -f "$HOOK_PATH/hook.sh" ]; then
  echo "  ✅ hook.sh found"
  HOOK_FILE="hook.sh"
  HOOK_LANG="bash"
else
  echo "  ❌ hook.py or hook.sh not found"
  ((ERRORS++))
  HOOK_LANG=""
fi

# 2. テストの存在確認
if [ -f "$HOOK_PATH/test.py" ]; then
  echo "  ✅ test.py found"
elif [ -f "$HOOK_PATH/test.sh" ]; then
  echo "  ✅ test.sh found"
else
  echo "  ⚠️  test file not found (recommended: test.py or test.sh)"
fi

# 3. 構文チェック
if [ "$HOOK_LANG" = "python" ]; then
  if python3 -c "import py_compile; py_compile.compile('$HOOK_PATH/hook.py', doraise=True)" 2>/dev/null; then
    echo "  ✅ hook.py syntax OK"
  else
    echo "  ❌ hook.py has syntax errors"
    ((ERRORS++))
  fi
elif [ "$HOOK_LANG" = "bash" ]; then
  if bash -n "$HOOK_PATH/hook.sh" 2>/dev/null; then
    echo "  ✅ hook.sh syntax OK"
  else
    echo "  ❌ hook.sh has syntax errors"
    ((ERRORS++))
  fi
fi

# 結果
echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "Validation passed ✅"
  exit 0
else
  echo "Validation failed: $ERRORS error(s) ❌"
  exit 1
fi
