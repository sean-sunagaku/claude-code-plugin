#!/bin/bash
# PR作成スクリプト - ベースブランチを自動検出（develop or main）
# Usage: ./create-pr.sh "PR Title" "PR Body"

set -e

TITLE="${1:-}"
BODY="${2:-}"

# ベースブランチを自動検出（develop があれば develop、なければ main）
git fetch origin --quiet
if git rev-parse --verify origin/develop >/dev/null 2>&1; then
  BASE_BRANCH="develop"
else
  BASE_BRANCH="main"
fi

# 引数チェック
if [ -z "$TITLE" ]; then
  echo "Error: PR title is required"
  echo "Usage: $0 \"PR Title\" \"PR Body\""
  exit 1
fi

# 現在のブランチ確認
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "develop" ]; then
  echo "Error: Cannot create PR from $CURRENT_BRANCH branch"
  exit 1
fi

# リモートにpush
echo "Pushing to origin/$CURRENT_BRANCH..."
git push -u origin "$CURRENT_BRANCH"

# PR作成
echo "Creating PR with base branch: $BASE_BRANCH"
gh pr create --base "$BASE_BRANCH" --title "$TITLE" --body "$BODY"
