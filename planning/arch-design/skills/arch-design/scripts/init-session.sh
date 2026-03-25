#!/usr/bin/env bash
# arch-design セッションディレクトリを初期化するスクリプト
# Usage: ./init-session.sh <design-slug>
#
# 全ステップのサブディレクトリを一括作成する。
# セッションルート直下にステップ成果物を置くことは禁止されており、
# 必ずこのスクリプトで作成されたディレクトリ内に配置すること。

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <design-slug>" >&2
  exit 1
fi

DESIGN_SLUG="$1"
SESSION_DIR=".claude/arch-design/sessions/${DESIGN_SLUG}"

# セッションディレクトリが既に存在する場合はエラー
if [ -d "$SESSION_DIR" ]; then
  echo "Error: Session directory already exists: $SESSION_DIR" >&2
  echo "Use a different design-slug or delete the existing session." >&2
  exit 1
fi

# 全ステップのディレクトリを一括作成
mkdir -p \
  "$SESSION_DIR/step1-context" \
  "$SESSION_DIR/step2-pattern-comparison/patterns" \
  "$SESSION_DIR/step3-module-design" \
  "$SESSION_DIR/step4-output"

echo "Session initialized: $SESSION_DIR"
echo ""
echo "Directory structure:"
echo "  $SESSION_DIR/"
echo "  ├── step1-context/                  # Step 1: 仕様・コンテキスト把握"
echo "  ├── step2-pattern-comparison/       # Step 2: パターン比較・選定"
echo "  │   └── patterns/                   # 各パターン案の詳細"
echo "  ├── step3-module-design/            # Step 3: モジュール設計・依存関係"
echo "  └── step4-output/                   # Step 4: 最終設計書"
