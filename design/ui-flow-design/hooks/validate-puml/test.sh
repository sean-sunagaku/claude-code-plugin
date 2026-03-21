#!/bin/bash
# test.sh - validate-puml hook のテスト
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/hook.sh"
ERRORS=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; ERRORS=$((ERRORS + 1)); }

# --- Test 1: 非 .puml ファイルは無視 ---
RESULT=$(echo '{"tool_input":{"file_path":"/tmp/test.ts"}}' | bash "$HOOK" 2>&1)
if [ -z "$RESULT" ]; then
  pass "non-.puml file is silently ignored"
else
  fail "non-.puml file should produce no output, got: $RESULT"
fi

# --- Test 2: 存在しない .puml ファイルは無視 ---
RESULT=$(echo '{"tool_input":{"file_path":"/tmp/nonexistent-test.puml"}}' | bash "$HOOK" 2>&1)
if [ -z "$RESULT" ]; then
  pass "nonexistent .puml file is silently ignored"
else
  fail "nonexistent .puml should produce no output, got: $RESULT"
fi

# --- Test 3: 正しい .puml ファイルは OK を返す ---
if command -v plantuml &>/dev/null; then
  TMP_PUML=$(mktemp /tmp/test-XXXXX.puml)
  cat > "$TMP_PUML" <<'PUML'
@startuml
Alice -> Bob: Hello
@enduml
PUML
  RESULT=$(echo "{\"tool_input\":{\"file_path\":\"$TMP_PUML\"}}" | bash "$HOOK" 2>&1)
  if echo "$RESULT" | grep -q "PlantUML OK"; then
    pass "valid .puml returns OK"
  else
    fail "valid .puml should return OK, got: $RESULT"
  fi
  rm -f "$TMP_PUML"

  # --- Test 4: @startuml/@enduml 不一致を検出 ---
  TMP_PUML=$(mktemp /tmp/test-XXXXX.puml)
  cat > "$TMP_PUML" <<'PUML'
@startuml
Alice -> Bob: Hello
PUML
  RESULT=$(echo "{\"tool_input\":{\"file_path\":\"$TMP_PUML\"}}" | bash "$HOOK" 2>&1)
  if echo "$RESULT" | grep -q "mismatch"; then
    pass "@startuml/@enduml mismatch detected"
  else
    fail "should detect @startuml/@enduml mismatch, got: $RESULT"
  fi
  rm -f "$TMP_PUML"
else
  echo "SKIP: plantuml not installed, skipping render tests"
fi

# --- Result ---
echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED ($ERRORS errors)"
  exit 1
else
  echo "ALL TESTS PASSED"
fi
