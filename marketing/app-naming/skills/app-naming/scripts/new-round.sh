#!/bin/bash
# app-naming: 新しいラウンドを作成
# Usage: bash scripts/new-round.sh <project-dir>
#
# 例: bash scripts/new-round.sh ~/.claude/app-naming/2026-02-18_miravy
#     → round-02/ を作成（round-01 が最後なら）

set -euo pipefail

PROJECT_DIR="${1:?Usage: bash scripts/new-round.sh <project-dir>}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "✗ Directory not found: ${PROJECT_DIR}"
  exit 1
fi

if [ ! -f "${PROJECT_DIR}/context.md" ]; then
  echo "✗ Not an app-naming project (context.md missing): ${PROJECT_DIR}"
  exit 1
fi

# 最新のラウンド番号を取得
LAST_ROUND=$(ls -d "${PROJECT_DIR}"/round-* 2>/dev/null | sort -V | tail -1 | grep -o '[0-9]*$' || echo "0")
NEXT_ROUND=$(printf "%02d" $((10#$LAST_ROUND + 1)))
ROUND_DIR="${PROJECT_DIR}/round-${NEXT_ROUND}"

mkdir -p "${ROUND_DIR}"

# 前ラウンドの最終候補を取得（candidates.md から）
PREV_CANDIDATES=""
if [ -f "${PROJECT_DIR}/round-${LAST_ROUND}/candidates.md" ]; then
  PREV_CANDIDATES="前ラウンド(round-${LAST_ROUND}/candidates.md)の最終候補を引き継いで絞り込む"
fi

cat > "${ROUND_DIR}/context.md" << ROUND_CONTEXT_EOF
# Round-${NEXT_ROUND} コンテキスト
${PREV_CANDIDATES:+# 引き継ぎ: ${PREV_CANDIDATES}}

## このラウンドの目的
（前ラウンドの結果を踏まえて記入）

## 前ラウンドから引き継いだ候補
（round-${LAST_ROUND}/candidates.md の最終候補を転記）

## 今回の評価方針
（絞り込み / 深堀り / 新候補追加 等）

## ファイル構成
round-${NEXT_ROUND}/
├── context.md      ← このファイル
├── log.md          ← 議事録
└── candidates.md   ← 候補と評価結果
ROUND_CONTEXT_EOF

cat > "${ROUND_DIR}/candidates.md" << CAND_EOF
# Round-${NEXT_ROUND} 候補リスト

## 引き継ぎ候補（前ラウンドより）

| No. | 候補名 | 前ラウンド総合 | このラウンドの評価ポイント |
|-----|--------|:------------:|--------------------------|
|     |        | /40          |                          |

## 評価結果サマリー

| 候補名 | ブランド | 法的リスク | デジタル | グローバル | 総合 | 推奨 |
|--------|:-------:|:---------:|:-------:|:---------:|:----:|:----:|
|        | /10     | 🟢🟡🔴    | /10     | /10       | /40  | ○/× |

## 却下候補と理由

| 候補名 | 却下理由 | 却下エージェント |
|--------|---------|----------------|

## ラウンド最終候補

1.
2.
3.
CAND_EOF

cat > "${ROUND_DIR}/log.md" << LOG_EOF
# Round-${NEXT_ROUND} 議事録

## セッション情報
- 日時: $(date +%Y-%m-%d)
- 参加エージェント: brand-strategist, legal-researcher, digital-presence, global-checker, context-manager

## タイムライン

### セッション開始
- 前ラウンド(round-${LAST_ROUND})からの引き継ぎ候補:

---

（以降はエージェントの議論を時系列で記録）
LOG_EOF

# context.md のラウンド履歴を更新
if grep -q "| round-${NEXT_ROUND} |" "${PROJECT_DIR}/context.md" 2>/dev/null; then
  echo "  (context.md already has round-${NEXT_ROUND} entry)"
else
  echo "| round-${NEXT_ROUND} | （目的を記入） | $(date +%Y-%m-%d) | 進行中 |" >> "${PROJECT_DIR}/context.md"
fi

echo "✓ Created: round-${NEXT_ROUND}"
echo "  ├── context.md"
echo "  ├── log.md"
echo "  └── candidates.md"
