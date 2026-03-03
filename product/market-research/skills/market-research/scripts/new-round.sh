#!/bin/bash
# 再調査ラウンド準備スクリプト
# Usage: bash scripts/new-round.sh <project-dir>
# data-critic が FAIL 判定した場合にチームリーダーが実行

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
for file in market-size.md trends.md demand-insights.md regulatory.md critique.md; do
  if [ -f "$PROJECT_DIR/$file" ]; then
    cp "$PROJECT_DIR/$file" "$PROJECT_DIR/${file%.md}_${TIMESTAMP}.bak.md"
    echo "バックアップ: $file → ${file%.md}_${TIMESTAMP}.bak.md"
  fi
done

echo ""
echo "準備完了。再調査結果は同じファイル名で上書きされます。"
echo "バックアップは .bak.md として保存済みです。"
