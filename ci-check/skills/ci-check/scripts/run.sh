#!/bin/bash
# CI Check - 全パッケージの lint / fmt:check / test を実行
set -e

# スクリプトのディレクトリからプロジェクトルートを特定
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$ROOT_DIR"

echo "🔍 CI Check"
echo "================================"
echo ""

# 結果を格納する変数
LINT_WEB=0
LINT_SERVER=0
LINT_SHARED=0
TYPECHECK_WEB=0
FMT_WEB=0
FMT_SERVER=0
FMT_SHARED=0
TEST_SERVER=0
AUDIT_WEB=0
AUDIT_SERVER=0

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# --- Lint ---
echo "📋 Lint"
echo "--------"

echo -n "  web:    "
if cd "$ROOT_DIR/packages/web" && pnpm run lint > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  LINT_WEB=1
fi

echo -n "  server: "
if cd "$ROOT_DIR/packages/server" && pnpm run lint > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  LINT_SERVER=1
fi

echo -n "  shared: "
if cd "$ROOT_DIR/packages/shared" && pnpm run lint > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  LINT_SHARED=1
fi

echo ""

# --- TypeCheck (web) ---
echo "🔷 TypeCheck"
echo "--------"

echo -n "  web:    "
if cd "$ROOT_DIR/packages/web" && pnpm run typecheck > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  TYPECHECK_WEB=1
fi

echo ""

# --- Format Check ---
echo "🎨 Format"
echo "--------"

echo -n "  web:    "
if cd "$ROOT_DIR/packages/web" && pnpm run fmt:check > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  FMT_WEB=1
fi

echo -n "  server: "
if cd "$ROOT_DIR/packages/server" && pnpm run fmt:check > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  FMT_SERVER=1
fi

echo -n "  shared: "
if cd "$ROOT_DIR/packages/shared" && pnpm run fmt:check > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  FMT_SHARED=1
fi

echo ""

# --- Test ---
echo "🧪 Test"
echo "--------"

echo -n "  server: "
if cd "$ROOT_DIR/packages/server" && pnpm run test > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  TEST_SERVER=1
fi

echo ""

# --- Audit ---
echo "🔒 Audit"
echo "--------"

echo -n "  web:    "
if cd "$ROOT_DIR/packages/web" && pnpm audit --audit-level=moderate > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  AUDIT_WEB=1
fi

echo -n "  server: "
if cd "$ROOT_DIR/packages/server" && pnpm audit --audit-level=moderate > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  AUDIT_SERVER=1
fi

echo ""
echo "================================"

# 結果サマリー
TOTAL_ERRORS=$((LINT_WEB + LINT_SERVER + LINT_SHARED + TYPECHECK_WEB + FMT_WEB + FMT_SERVER + FMT_SHARED + TEST_SERVER + AUDIT_WEB + AUDIT_SERVER))

if [ $TOTAL_ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ All checks passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ $TOTAL_ERRORS check(s) failed${NC}"
  echo ""

  # 失敗したチェックを表示
  [ $LINT_WEB -eq 1 ] && echo "  - lint: web"
  [ $LINT_SERVER -eq 1 ] && echo "  - lint: server"
  [ $LINT_SHARED -eq 1 ] && echo "  - lint: shared"
  [ $TYPECHECK_WEB -eq 1 ] && echo "  - typecheck: web"
  [ $FMT_WEB -eq 1 ] && echo "  - fmt: web"
  [ $FMT_SERVER -eq 1 ] && echo "  - fmt: server"
  [ $FMT_SHARED -eq 1 ] && echo "  - fmt: shared"
  [ $TEST_SERVER -eq 1 ] && echo "  - test: server"
  [ $AUDIT_WEB -eq 1 ] && echo "  - audit: web"
  [ $AUDIT_SERVER -eq 1 ] && echo "  - audit: server"

  exit 1
fi
