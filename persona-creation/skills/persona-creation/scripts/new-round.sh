#!/bin/bash
# 新ラウンド作成スクリプト
# Usage: bash scripts/new-round.sh <project-dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: bash scripts/new-round.sh <project-dir>}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR does not exist"
  exit 1
fi

# Find next round number
LAST_ROUND=$(ls -d "$PROJECT_DIR"/round-* 2>/dev/null | sort -V | tail -1 | grep -oP '\d+$' || echo "00")
NEXT_ROUND=$(printf "%02d" $((10#$LAST_ROUND + 1)))
ROUND_DIR="$PROJECT_DIR/round-$NEXT_ROUND"

mkdir -p "$ROUND_DIR"

cat > "$ROUND_DIR/context.md" << EOF
# Round-$NEXT_ROUND コンテキスト

## このラウンドの目的
（TODO）

## 前回ラウンドからの引き継ぎ
（TODO）

## 制約・評価基準
（TODO）
EOF

cat > "$ROUND_DIR/log.md" << EOF
# Round-$NEXT_ROUND 議事録

## セッション情報
- 日時: $(date '+%Y-%m-%d %H:%M')
- 参加エージェント: persona-architect, user-researcher, persona-writer, bias-reviewer, context-manager

## タイムライン

（セッション開始後に記録）
EOF

cat > "$ROUND_DIR/segments.md" << 'EOF'
# ユーザーセグメント

## セグメント一覧

| No. | セグメント名 | 推定規模 | プロダクトとの関係 | 主要ニーズ |
|-----|-------------|---------|-------------------|-----------|
| 1   |             |         |                   |           |

## 評価結果

| セグメント | アーキテクト | リサーチャー | バイアス | 採用 |
|-----------|------------|------------|---------|------|
|           |            |            |         |      |
EOF

echo "Created: $ROUND_DIR"
