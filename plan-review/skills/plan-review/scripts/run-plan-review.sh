#!/bin/bash
# Codex + Gemini + Claude による Plan レビューを並列実行

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# デフォルト設定
WORK_DIR="${WORK_DIR:-$(pwd)}"
REVIEW_NAME=""
RUN_CODEX=true
RUN_GEMINI=true
RUN_CLAUDE=true

# ヘルプ表示
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] <plan_file>

Plan ファイルを Codex、Gemini、Claude で並列レビュー

OPTIONS:
  -c, --codex-only    Codex のみ実行
  -g, --gemini-only   Gemini のみ実行
  -l, --claude-only   Claude のみ実行
  --no-codex          Codex を除外
  --no-gemini         Gemini を除外
  --no-claude         Claude を除外
  -n, --name NAME     出力ディレクトリ名を指定
  -h, --help          このヘルプを表示

EXAMPLES:
  $0 docs/plans/my-feature.md
  $0 --codex-only docs/plans/my-feature.md
  $0 --no-claude docs/plans/my-feature.md
  $0 --name my-review docs/plans/my-feature.md
EOF
}

# 引数解析
PLAN_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--codex-only)
            RUN_CODEX=true
            RUN_GEMINI=false
            RUN_CLAUDE=false
            shift
            ;;
        -g|--gemini-only)
            RUN_CODEX=false
            RUN_GEMINI=true
            RUN_CLAUDE=false
            shift
            ;;
        -l|--claude-only)
            RUN_CODEX=false
            RUN_GEMINI=false
            RUN_CLAUDE=true
            shift
            ;;
        --no-codex)
            RUN_CODEX=false
            shift
            ;;
        --no-gemini)
            RUN_GEMINI=false
            shift
            ;;
        --no-claude)
            RUN_CLAUDE=false
            shift
            ;;
        -n|--name)
            REVIEW_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            PLAN_FILE="$1"
            shift
            ;;
    esac
done

# Plan ファイルチェック
if [ -z "$PLAN_FILE" ]; then
    echo "Error: Plan file required"
    show_help
    exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
    echo "Error: Plan file not found: $PLAN_FILE"
    exit 1
fi

# 出力ディレクトリ設定
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
if [ -n "$REVIEW_NAME" ]; then
    FINAL_NAME="${TIMESTAMP}_${REVIEW_NAME}"
else
    FINAL_NAME="$TIMESTAMP"
fi
OUTPUT_DIR="${OUTPUT_DIR:-$SKILL_DIR/results/$FINAL_NAME}"

export WORK_DIR
export OUTPUT_DIR
export REVIEW_NAME="$FINAL_NAME"

echo "========================================"
echo "Plan Review (3 AI Parallel)"
echo "========================================"
echo "Plan file: $PLAN_FILE"
echo "Output dir: $OUTPUT_DIR"
echo "Codex:  $RUN_CODEX"
echo "Gemini: $RUN_GEMINI"
echo "Claude: $RUN_CLAUDE"
echo "========================================"
echo ""

mkdir -p "$OUTPUT_DIR"

# 並列実行
PIDS=()

if [ "$RUN_CODEX" = true ]; then
    echo "Starting Codex review..."
    "$SCRIPT_DIR/codex-plan-review.sh" "$PLAN_FILE" &
    PIDS+=($!)
fi

if [ "$RUN_GEMINI" = true ]; then
    echo "Starting Gemini review..."
    "$SCRIPT_DIR/gemini-plan-review.sh" "$PLAN_FILE" &
    PIDS+=($!)
fi

if [ "$RUN_CLAUDE" = true ]; then
    echo "Starting Claude review..."
    "$SCRIPT_DIR/claude-plan-review.sh" "$PLAN_FILE" &
    PIDS+=($!)
fi

# 完了待機
FAILED=0
for pid in "${PIDS[@]}"; do
    if ! wait "$pid"; then
        FAILED=1
    fi
done

echo ""
echo "========================================"
echo "Plan Review Complete"
echo "========================================"
echo "Results: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
echo "========================================"

if [ "$FAILED" -ne 0 ]; then
    echo "Warning: Some reviews may have failed"
    exit 1
fi
