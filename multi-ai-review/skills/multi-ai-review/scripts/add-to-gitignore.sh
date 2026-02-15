#!/bin/bash
# Multi-AI Review 初期化スクリプト
# .gitignore に results/ を追加する

set -e

# 色付き出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# .gitignore に追加
GITIGNORE_ENTRY=".claude/skills/multi-ai-review/results/"

# Gitリポジトリのルートを取得
GITIGNORE_FILE="$(git rev-parse --show-toplevel 2>/dev/null)/.gitignore"

if [ -z "$GITIGNORE_FILE" ]; then
    print_warning "Not a git repository"
    exit 1
fi

if [ ! -f "$GITIGNORE_FILE" ]; then
    echo "$GITIGNORE_ENTRY" > "$GITIGNORE_FILE"
    print_status "Created .gitignore with results/ entry"
elif grep -qF "$GITIGNORE_ENTRY" "$GITIGNORE_FILE"; then
    print_status ".gitignore already contains results/ entry"
else
    echo "" >> "$GITIGNORE_FILE"
    echo "# Multi-AI Review results" >> "$GITIGNORE_FILE"
    echo "$GITIGNORE_ENTRY" >> "$GITIGNORE_FILE"
    print_status "Added results/ to .gitignore"
fi

echo ""
echo "Done! results/ directory will be ignored by git."
