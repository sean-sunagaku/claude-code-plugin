#!/bin/bash
# Codex によるコードレビュー実行スクリプト

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 設定
WORK_DIR="${WORK_DIR:-$(pwd)}"
REVIEW_NAME="${REVIEW_NAME:-$(date +%Y%m%d_%H%M%S)}"
OUTPUT_DIR="${OUTPUT_DIR:-$SKILL_DIR/results/$REVIEW_NAME}"
OUTPUT_FILE="${OUTPUT_DIR}/codex_review.md"

# 出力ディレクトリ作成
mkdir -p "$OUTPUT_DIR"

# 引数チェック
if [ -z "$1" ]; then
    echo "Usage: $0 <file1> [file2] [file3] ..."
    echo "       $0 --stdin  (read files from stdin)"
    exit 1
fi

# ファイルリスト取得
if [ "$1" = "--stdin" ]; then
    FILES=$(cat)
else
    FILES="$*"
fi

# ファイルリストをフォーマット
FILE_LIST=""
for f in $FILES; do
    FILE_LIST="${FILE_LIST}- ${f}\n"
done

# レビュープロンプト
PROMPT="以下のファイルをコードレビューしてください。
問題点、改善提案、良い点をそれぞれ挙げてください。

対象ファイル:
${FILE_LIST}

出力形式:
## 問題点
- [問題1]: 説明
- [問題2]: 説明

## 改善提案
- [提案1]: 説明
- [提案2]: 説明

## 良い点
- [良い点1]: 説明
- [良い点2]: 説明

## 総合評価
[S/A/B/C/D の5段階評価と理由]"

echo "=== Codex Review Starting ==="
echo "Output: $OUTPUT_FILE"
echo "Files: $FILES"
echo ""

# Codex 実行
codex exec --full-auto -C "$WORK_DIR" -o "$OUTPUT_FILE" "$PROMPT"

echo ""
echo "=== Codex Review Complete ==="
echo "Result saved to: $OUTPUT_FILE"
