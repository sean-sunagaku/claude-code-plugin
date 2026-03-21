#!/bin/bash
# test.sh - validate-marketplace hook のテスト
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/hook.sh"
ERRORS=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; ERRORS=$((ERRORS + 1)); }

# --- Test 1: plugin repo 外のファイルは無視 ---
RESULT=$(echo '{"tool_input":{"file_path":"/tmp/marketplace.json"}}' | bash "$HOOK" 2>&1)
if [ -z "$RESULT" ]; then
  pass "file outside plugin repo is ignored"
else
  fail "should ignore file outside plugin repo, got: $RESULT"
fi

# --- Test 2: 対象外のファイル名は無視 ---
RESULT=$(echo '{"tool_input":{"file_path":"/Users/babashunsuke/Repository/claude-code-plugin/README.md"}}' | bash "$HOOK" 2>&1)
if [ -z "$RESULT" ]; then
  pass "non-target file (README.md) is ignored"
else
  fail "should ignore non-target file, got: $RESULT"
fi

# --- Test 3: marketplace.json の編集でバリデーション実行 ---
RESULT=$(echo '{"tool_input":{"file_path":"/Users/babashunsuke/Repository/claude-code-plugin/.claude-plugin/marketplace.json"}}' | bash "$HOOK" 2>&1)
if echo "$RESULT" | grep -q "Marketplace Validation"; then
  pass "marketplace.json triggers validation"
else
  fail "marketplace.json should trigger validation, got: $RESULT"
fi

# --- Test 4: plugin.json の編集でバリデーション実行 ---
RESULT=$(echo '{"tool_input":{"file_path":"/Users/babashunsuke/Repository/claude-code-plugin/design/ui-flow-design/plugin.json"}}' | bash "$HOOK" 2>&1)
if echo "$RESULT" | grep -q "Marketplace Validation"; then
  pass "plugin.json triggers validation"
else
  fail "plugin.json should trigger validation, got: $RESULT"
fi

# --- Result ---
echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED ($ERRORS errors)"
  exit 1
else
  echo "ALL TESTS PASSED"
fi
