#!/bin/bash
# logo-design: 新しいステップを作成
# Usage: bash scripts/new-step.sh <project-dir>
#
# 例: bash scripts/new-step.sh ~/.claude/logo-design/2026-02-18_miravy
#     → step-02/ を作成（step-01 が最後なら）

set -euo pipefail

PROJECT_DIR="${1:?Usage: bash scripts/new-step.sh <project-dir>}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "✗ Directory not found: ${PROJECT_DIR}"
  exit 1
fi

if [ ! -f "${PROJECT_DIR}/context.md" ]; then
  echo "✗ Not a logo-design project (context.md missing): ${PROJECT_DIR}"
  exit 1
fi

# 最新のステップ番号を取得
LAST_STEP=$(ls -d "${PROJECT_DIR}"/step-* 2>/dev/null | sort -V | tail -1 | grep -o '[0-9]*$' || echo "0")
NEXT_STEP=$(printf "%02d" $((10#$LAST_STEP + 1)))
STEP_DIR="${PROJECT_DIR}/step-${NEXT_STEP}"

mkdir -p "${STEP_DIR}/logos"

# 前のステップの log.md 末尾を参照メモとして追加
PREV_NOTE=""
if [ -f "${PROJECT_DIR}/step-${LAST_STEP}/log.md" ]; then
  PREV_NOTE="前ステップ step-${LAST_STEP}/log.md の「次ステップへの指針」を反映すること"
fi

cat > "${STEP_DIR}/context.md" << STEP_CONTEXT_EOF
# Step-${NEXT_STEP} コンテキスト
${PREV_NOTE:+# NOTE: ${PREV_NOTE}}

## このステップの目的
（前ステップの結果を踏まえて記入）

## 探求する方向性
（エージェントと相談して決定）

## 制約
（あれば記入）

## ファイル構成
step-${NEXT_STEP}/
├── context.md   ← このファイル
├── log.md       ← 議事録
└── logos/       ← 生成したロゴ（SVG等）
STEP_CONTEXT_EOF

cat > "${STEP_DIR}/log.md" << LOG_EOF
# Step-${NEXT_STEP} 議事録

## セッション情報
- 日時: $(date +%Y-%m-%d)
- 参加エージェント: brand-strategist, competitive-analyst, trend-researcher, logo-designer, color-type-expert, context-manager

## タイムライン

### セッション開始
- 前ステップ(step-${LAST_STEP})からの引き継ぎ事項:

---

（以降はエージェントの議論を時系列で記録）
LOG_EOF

# context.md のステップ履歴を更新
if grep -q "| step-${NEXT_STEP} |" "${PROJECT_DIR}/context.md" 2>/dev/null; then
  echo "  (context.md already has step-${NEXT_STEP} entry)"
else
  echo "| step-${NEXT_STEP} | （目的を記入） | $(date +%Y-%m-%d) | 進行中 |" >> "${PROJECT_DIR}/context.md"
fi

echo "✓ Created: step-${NEXT_STEP}"
echo "  ├── context.md"
echo "  ├── log.md"
echo "  └── logos/"
