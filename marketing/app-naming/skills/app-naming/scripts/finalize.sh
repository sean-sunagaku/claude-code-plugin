#!/bin/bash
# app-naming: 最終候補まとめとレポート生成
# Usage: bash scripts/finalize.sh <project-dir> <round-number>
#
# 例: bash scripts/finalize.sh ~/.claude/app-naming/2026-02-18_miravy 02
#     → round-02 の結果で final/ を作成しレポートテンプレート生成

set -euo pipefail

PROJECT_DIR="${1:?Usage: bash scripts/finalize.sh <project-dir> <round-number>}"
ROUND_NUM="${2:?Specify round number (e.g., 02)}"

ROUND_DIR="${PROJECT_DIR}/round-${ROUND_NUM}"
FINAL_DIR="${PROJECT_DIR}/final"

if [ ! -d "$ROUND_DIR" ]; then
  echo "✗ Round directory not found: ${ROUND_DIR}"
  exit 1
fi

mkdir -p "${FINAL_DIR}"

# 最終ラウンドの candidates.md をコピー
if [ -f "${ROUND_DIR}/candidates.md" ]; then
  cp "${ROUND_DIR}/candidates.md" "${FINAL_DIR}/final-candidates.md"
  echo "  ✓ Copied: final-candidates.md"
fi

# レポートテンプレート生成
TOTAL_ROUNDS=$(ls -d "${PROJECT_DIR}"/round-* 2>/dev/null | wc -l | tr -d ' ')

cat > "${FINAL_DIR}/report.md" << REPORT_EOF
# アプリ名 最終決定レポート

## 概要

| 項目 | 内容 |
|------|------|
| プロジェクト | $(basename "$PROJECT_DIR") |
| 作成日 | $(date +%Y-%m-%d) |
| ラウンド数 | ${TOTAL_ROUNDS} |
| 最終ラウンド | round-${ROUND_NUM} |

## 最終推奨候補

| 順位 | 候補名 | 総合スコア | ブランド | 法的 | デジタル | グローバル |
|------|--------|:---------:|:-------:|:---:|:-------:|:---------:|
| 1位  |        | /40       | /10     | /10 | /10     | /10       |
| 2位  |        | /40       | /10     | /10 | /10     | /10       |
| 3位  |        | /40       | /10     | /10 | /10     | /10       |

## 推奨候補の詳細

### 1位: {候補名}

**選定理由**:

**使用上の注意**:

**将来の展開**:

---

## ラウンド別経緯

$(for r in $(ls -d "${PROJECT_DIR}"/round-* 2>/dev/null | sort -V); do
  rname=$(basename "$r")
  echo "### ${rname}"
  echo "- 目的:"
  echo "- 結果:"
  echo "- 主な却下理由:"
  echo ""
done)

## 却下された候補と理由

| 候補名 | 却下理由 | 却下ラウンド |
|--------|---------|------------|
|        |         |            |

## 次のアクション

- [ ] 商標出願の検討
- [ ] ドメイン取得（.com / .jp / .app）
- [ ] SNSアカウント（@{候補名}）の確保
- [ ] App Store / Google Play での名前確認
- [ ] デザインチームへのロゴ発注

## 参考: 評価した全候補

→ [final-candidates.md](final-candidates.md) を参照
REPORT_EOF

echo ""
echo "✓ Finalized: ${FINAL_DIR}"
echo "  ├── final-candidates.md"
echo "  └── report.md"
echo ""
echo "Next steps:"
echo "  1. report.md を編集して最終推奨候補の詳細を記入"
echo "  2. SUMMARY.md を更新"
echo "  3. context.md の「学んだこと」に追記"
