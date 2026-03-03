#!/bin/bash
# 再調査ラウンド準備スクリプト
# Usage: bash scripts/new-round.sh <project-dir>
# ca-data-critic が FAIL 判定した場合にチームリーダーが実行

set -euo pipefail

PROJECT_DIR="${1:?Usage: bash scripts/new-round.sh <project-dir>}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "ERROR: Directory not found: $PROJECT_DIR"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== 再調査ラウンド準備 ==="
echo "プロジェクトディレクトリ: $PROJECT_DIR"
echo ""

# 既存ファイルをバックアップ
for file in competitor-profiles.md review-insights.md feature-matrix.md positioning.md critique.md; do
  if [ -f "$PROJECT_DIR/$file" ]; then
    cp "$PROJECT_DIR/$file" "$PROJECT_DIR/${file%.md}_${TIMESTAMP}.bak.md"
    echo "バックアップ: $file → ${file%.md}_${TIMESTAMP}.bak.md"
  fi
done

echo ""
echo "準備完了。再調査結果は同じファイル名で上書きされます。"
echo "バックアップは .bak.md として保存済みです。"
echo ""
echo "再調査後のフロー:"
echo "1. ca-data-critic の FAIL 判定理由を確認"
echo "2. 該当エージェント（ca-competitor-researcher / ca-review-analyst / ca-feature-benchmarker）に再調査を指示"
echo "3. Phase 1 ディスカッションを再開"
echo "4. ca-data-critic が Gate 1 を再判定"
echo "注意: 再調査は最大2ラウンドまで。3回目で FAIL なら信頼度 Low としてレポートに明記。"
