#!/bin/bash
# Claude による Plan レビュー実行スクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 設定
WORK_DIR="${WORK_DIR:-$(pwd)}"
REVIEW_NAME="${REVIEW_NAME:-$(date +%Y%m%d_%H%M%S)}"
OUTPUT_DIR="${OUTPUT_DIR:-$SKILL_DIR/results/$REVIEW_NAME}"
OUTPUT_FILE="${OUTPUT_DIR}/claude_review.md"

mkdir -p "$OUTPUT_DIR"

# 引数チェック
if [ -z "$1" ]; then
    echo "Usage: $0 <plan_file>"
    exit 1
fi

PLAN_FILE="$1"

if [ ! -f "$PLAN_FILE" ]; then
    echo "Error: Plan file not found: $PLAN_FILE"
    exit 1
fi

# Plan レビュー用プロンプト
PROMPT="以下の実装計画（Plan）をレビューしてください。

対象ファイル: ${PLAN_FILE}

## レビュー観点

### 1. 実装計画の妥当性
- 要件に対して計画が適切か
- 技術選定は妥当か
- アーキテクチャ設計に問題はないか

### 2. 抜け漏れ
- 考慮すべきエッジケースはないか
- エラーハンドリングは考慮されているか
- テスト計画は十分か

### 3. リスク
- 実装上のリスクはないか
- パフォーマンスへの影響はないか
- セキュリティ上の懸念はないか

### 4. 改善提案
- より良いアプローチはないか
- 既存コードとの整合性は取れているか

## 出力形式

### 計画の妥当性
[評価とコメント]

### 抜け漏れ・懸念点
- [項目1]: 説明
- [項目2]: 説明

### リスク
- [リスク1]: 説明と対策案
- [リスク2]: 説明と対策案

### 改善提案
- [提案1]: 説明
- [提案2]: 説明

### 総合評価
[S/A/B/C/D の5段階評価と理由]"

echo "=== Claude Plan Review Starting ==="
echo "Plan: $PLAN_FILE"
echo "Output: $OUTPUT_FILE"
echo ""

# Claude 実行（非対話モード）
cd "$WORK_DIR"
claude -p --permission-mode bypassPermissions "$PROMPT" > "$OUTPUT_FILE" 2>/dev/null

echo ""
echo "=== Claude Plan Review Complete ==="
echo "Result saved to: $OUTPUT_FILE"
