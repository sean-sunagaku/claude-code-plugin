#!/bin/bash
# app-naming: プロジェクト初期化
# Usage: bash scripts/init.sh <project-name>
#
# 例: bash scripts/init.sh miravy
#     → .claude/app-naming/2026-02-18_miravy/ を作成

set -euo pipefail

PROJECT_NAME="${1:?Usage: bash scripts/init.sh <project-name>}"
DATE=$(date +%Y-%m-%d)
BASE_DIR="${HOME}/.claude/app-naming"
PROJECT_DIR="${BASE_DIR}/${DATE}_${PROJECT_NAME}"

if [ -d "$PROJECT_DIR" ]; then
  echo "⚠ Already exists: ${PROJECT_DIR}"
  echo "  Use new-round.sh to add a new round."
  exit 1
fi

# ディレクトリ構造作成
mkdir -p "${PROJECT_DIR}/round-01"

# 全体 context.md テンプレート
cat > "${PROJECT_DIR}/context.md" << 'CONTEXT_EOF'
# App Naming Context

## アプリ情報
- アプリ名（現行）:
- 概要:
- コア機能:
- ターゲット:
- 名前の方向性: 日本語名 / 英語名 / 造語 / 指定なし
- 国際展開: 日本限定 / 海外展開予定
- 好みのトーン: クール / 親しみやすい / プロフェッショナル

## 制約・好み
- 避けたいパターン:
- 文字数制限:
- 参考にしたい名前:

## 過去のラウンドで学んだこと
（各ラウンド終了後に追記）

## ラウンド履歴
| Round | 目的 | 日時 | 最終候補 |
|-------|------|------|---------|
| round-01 | 初回候補提案 | - | 進行中 |
CONTEXT_EOF

# round-01 context.md テンプレート
cat > "${PROJECT_DIR}/round-01/context.md" << 'ROUND_CONTEXT_EOF'
# Round-01 コンテキスト

## このラウンドの目的
初回候補提案 - brand-strategist が15案を提案し、各観点で評価・絞り込む

## 評価基準の重みづけ
- ブランド力: 25%
- 法的安全性: 25%
- デジタルプレゼンス: 25%
- グローバル展開: 25%

## ファイル構成
round-01/
├── context.md      ← このファイル
├── log.md          ← 議事録
└── candidates.md   ← 候補と評価結果
ROUND_CONTEXT_EOF

# round-01 candidates.md テンプレート
cat > "${PROJECT_DIR}/round-01/candidates.md" << 'CAND_EOF'
# Round-01 候補リスト

## 提案候補（brand-strategist）

| No. | 候補名 | 読み | コンセプト | ブランドスコア |
|-----|--------|------|-----------|:------------:|
| 1   |        |      |           |    /10       |
| 2   |        |      |           |    /10       |
| 3   |        |      |           |    /10       |
| 4   |        |      |           |    /10       |
| 5   |        |      |           |    /10       |

## 評価結果サマリー

| 候補名 | ブランド | 法的リスク | デジタル | グローバル | 総合 | 推奨 |
|--------|:-------:|:---------:|:-------:|:---------:|:----:|:----:|
|        | /10     | 🟢🟡🔴    | /10     | /10       | /40  | ○/× |

## 却下候補と理由

| 候補名 | 却下理由 | 却下エージェント |
|--------|---------|----------------|
|        |         |                |

## ラウンド最終候補（上位5）

1.
2.
3.
4.
5.
CAND_EOF

# round-01 log.md テンプレート
cat > "${PROJECT_DIR}/round-01/log.md" << 'LOG_EOF'
# Round-01 議事録

## セッション情報
- 日時:
- 参加エージェント: brand-strategist, legal-researcher, digital-presence, global-checker, context-manager

## タイムライン

### セッション開始
- ヒアリング完了
- アプリ情報: （要約）

---

（以降はエージェントの議論を時系列で記録）
LOG_EOF

# SUMMARY.md テンプレート
cat > "${PROJECT_DIR}/SUMMARY.md" << 'SUMMARY_EOF'
# App Naming Summary

## プロジェクト概要

## ラウンド別サマリー

### Round-01
- 目的:
- 提案数:
- 残った候補:
- 学んだこと:

## 最終決定候補

| 順位 | 候補名 | 総合スコア | 推奨理由 |
|------|--------|-----------|---------|
| 1位  |        | /40       |         |
| 2位  |        | /40       |         |
| 3位  |        | /40       |         |

## 次回への引き継ぎ
SUMMARY_EOF

echo "✓ Created: ${PROJECT_DIR}"
echo "  ├── context.md"
echo "  ├── SUMMARY.md"
echo "  └── round-01/"
echo "      ├── context.md"
echo "      ├── log.md"
echo "      └── candidates.md"
echo ""
echo "Next: Edit context.md with app info, then start the agent team."
