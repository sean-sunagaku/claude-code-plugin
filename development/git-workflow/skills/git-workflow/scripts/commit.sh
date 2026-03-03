#!/bin/bash
# コミットスクリプト - Co-Authored-By を自動付与
# Usage: ./commit.sh "<commit message>"
# Example: ./commit.sh "feat(web): add login component"

set -e

MESSAGE="${1:-}"
CO_AUTHOR="Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

# 引数チェック
if [ -z "$MESSAGE" ]; then
  echo "Error: Commit message is required"
  echo "Usage: $0 \"<commit message>\""
  echo "Example: $0 \"feat(web): add login component\""
  exit 1
fi

# ステージされた変更があるか確認
if git diff --cached --quiet; then
  echo "Error: No staged changes to commit"
  echo "Run 'git add <files>' first"
  exit 1
fi

# コミットメッセージのフォーマット確認
if [[ ! "$MESSAGE" =~ ^(feat|fix|refactor|docs|chore|perf|test|ci|style|revert)(\(.+\))?\!?:\ .+ ]]; then
  echo "Warning: Commit message should follow Conventional Commits format"
  echo "Format: <type>(<scope>): <description>"
  echo "Example: feat(web): add login component"
  read -p "Continue anyway? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    exit 1
  fi
fi

# コミット実行
git commit -m "$MESSAGE

$CO_AUTHOR"

echo ""
echo "✅ Committed with Co-Authored-By"
