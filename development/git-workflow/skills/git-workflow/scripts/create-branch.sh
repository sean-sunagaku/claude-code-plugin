#!/bin/bash
# ブランチ作成スクリプト - develop or main から分岐（自動検出）
# Usage: ./create-branch.sh <branch-name>
# Example: ./create-branch.sh feat/add-login

set -e

BRANCH_NAME="${1:-}"

# 引数チェック
if [ -z "$BRANCH_NAME" ]; then
  echo "Error: Branch name is required"
  echo "Usage: $0 <branch-name>"
  echo "Example: $0 feat/add-login"
  exit 1
fi

# ブランチ名のバリデーション
if [[ ! "$BRANCH_NAME" =~ ^(feat|fix|refactor|docs|chore|perf|test|ci|update)/ ]]; then
  echo "Warning: Branch name should follow convention: <type>/<description>"
  echo "Types: feat, fix, refactor, docs, chore, perf, test, ci, update"
  echo "Example: feat/add-login, fix/auth-bug"
  read -p "Continue anyway? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    exit 1
  fi
fi

# リモートの最新を取得
echo "Fetching latest from origin..."
git fetch origin

# ベースブランチを自動検出（develop があれば develop、なければ main）
if git rev-parse --verify origin/develop >/dev/null 2>&1; then
  BASE_BRANCH="develop"
else
  BASE_BRANCH="main"
fi
echo "Base branch: $BASE_BRANCH"

# ベースブランチを最新に pull してからブランチ作成
echo "Switching to $BASE_BRANCH and pulling latest..."
git checkout "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"

echo "Creating branch: $BRANCH_NAME from $BASE_BRANCH"
git checkout -b "$BRANCH_NAME"

echo ""
echo "✅ Branch created: $BRANCH_NAME"
echo "   Base: $BASE_BRANCH (latest)"
