#!/bin/bash
# Multi-AI Review メインスクリプト
# Codex、Gemini、Claude を並列実行し、結果を統合する

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="${WORK_DIR:-$(pwd)}"
REVIEW_NAME="${REVIEW_NAME:-$(date +%Y%m%d_%H%M%S)}"
OUTPUT_DIR="${OUTPUT_DIR:-$SKILL_DIR/results/$REVIEW_NAME}"
REPORT_FILE="${REPORT_FILE:-$OUTPUT_DIR/multi-ai-review-results.md}"

# 出力ディレクトリ作成
mkdir -p "$OUTPUT_DIR"

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Multi-AI Code Review (3 AI Parallel)${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 使用方法
usage() {
    echo "Usage: $0 [options] <file1> [file2] [file3] ..."
    echo ""
    echo "Options:"
    echo "  -d, --diff REF      指定したコミット/ブランチとの差分をレビュー"
    echo "  -c, --codex-only    Codex のみ実行"
    echo "  -m, --gemini-only   Gemini のみ実行"
    echo "  -l, --claude-only   Claude のみ実行"
    echo "  --no-codex          Codex を除外"
    echo "  --no-gemini         Gemini を除外"
    echo "  --no-claude         Claude を除外"
    echo "  -n, --name NAME     レビューディレクトリ名を指定"
    echo "  -h, --help          ヘルプを表示"
    echo ""
    echo "Examples:"
    echo "  $0 src/app/page.tsx src/lib/utils.ts"
    echo "  $0 --diff develop           # developとの差分"
    echo "  $0 --diff HEAD~5            # 直近5コミット"
    echo "  $0 --diff abc1234           # 特定コミットまで"
    echo "  $0 --diff develop --name feature-review"
    echo "  $0 --no-claude --diff develop  # Claude を除外"
    echo ""
    echo "Optional:"
    echo "  ./scripts/add-to-gitignore.sh  # results/ を .gitignore に追加"
}

# 引数解析
DIFF_REF=""
RUN_CODEX=true
RUN_GEMINI=true
RUN_CLAUDE=true
FILES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--diff)
            DIFF_REF="$2"
            shift 2
            ;;
        -c|--codex-only)
            RUN_CODEX=true
            RUN_GEMINI=false
            RUN_CLAUDE=false
            shift
            ;;
        -m|--gemini-only)
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
            REVIEW_NAME="$(date +%Y%m%d_%H%M%S)_$2"
            OUTPUT_DIR="$SKILL_DIR/results/$REVIEW_NAME"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

print_header

# ファイルリスト取得
if [ -n "$DIFF_REF" ]; then
    print_status "Getting changed files compared to $DIFF_REF ..."
    FILE_LIST=$(git diff --name-only "$DIFF_REF" 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$' | head -20 || true)
    if [ -z "$FILE_LIST" ]; then
        print_error "No TypeScript/JavaScript files found in diff with $DIFF_REF"
        exit 1
    fi
elif [ ${#FILES[@]} -gt 0 ]; then
    FILE_LIST="${FILES[*]}"
else
    print_error "No files specified. Use --diff or provide file paths."
    usage
    exit 1
fi

echo ""
print_status "Review target files:"
echo "$FILE_LIST" | while read -r f; do echo "  - $f"; done
echo ""
print_status "AI Reviewers: Codex=$RUN_CODEX, Gemini=$RUN_GEMINI, Claude=$RUN_CLAUDE"
echo ""

# 出力ディレクトリ作成
mkdir -p "$OUTPUT_DIR"

# PIDを保存する配列
PIDS=()

# Codex 実行
if [ "$RUN_CODEX" = true ]; then
    print_status "Starting Codex review..."
    echo "$FILE_LIST" | OUTPUT_DIR="$OUTPUT_DIR" "$SCRIPT_DIR/codex-review.sh" --stdin &
    PIDS+=($!)
fi

# Gemini 実行
if [ "$RUN_GEMINI" = true ]; then
    print_status "Starting Gemini review..."
    echo "$FILE_LIST" | OUTPUT_DIR="$OUTPUT_DIR" "$SCRIPT_DIR/gemini-review.sh" --stdin &
    PIDS+=($!)
fi

# Claude 実行
if [ "$RUN_CLAUDE" = true ]; then
    print_status "Starting Claude review..."
    echo "$FILE_LIST" | OUTPUT_DIR="$OUTPUT_DIR" "$SCRIPT_DIR/claude-review.sh" --stdin &
    PIDS+=($!)
fi

# 全プロセスの完了を待機
print_status "Waiting for reviews to complete..."
FAILED=false
for pid in "${PIDS[@]}"; do
    if ! wait "$pid"; then
        print_warning "Process $pid failed"
        FAILED=true
    fi
done

echo ""
print_status "Reviews completed!"

# 結果ファイルの確認
echo ""
print_status "Results:"
if [ -f "$OUTPUT_DIR/codex_review.md" ]; then
    echo "  - Codex:  $OUTPUT_DIR/codex_review.md"
else
    [ "$RUN_CODEX" = true ] && print_warning "  - Codex:  (not found)"
fi

if [ -f "$OUTPUT_DIR/gemini_review.md" ]; then
    echo "  - Gemini: $OUTPUT_DIR/gemini_review.md"
else
    [ "$RUN_GEMINI" = true ] && print_warning "  - Gemini: (not found)"
fi

if [ -f "$OUTPUT_DIR/claude_review.md" ]; then
    echo "  - Claude: $OUTPUT_DIR/claude_review.md"
else
    [ "$RUN_CLAUDE" = true ] && print_warning "  - Claude: (not found)"
fi

echo ""
print_status "Result files location: $OUTPUT_DIR"
echo ""
