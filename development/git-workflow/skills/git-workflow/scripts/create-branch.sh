#!/bin/bash
# ブランチ作成スクリプト - develop から分岐
# Usage: ./create-branch.sh <branch-name>
# Example: ./create-branch.sh feat/add-login

set -e

BRANCH_NAME="${1:-}"
BASE_BRANCH="develop"

# 引数チェック
if [ -z "$BRANCH_NAME" ]; then
  echo "Error: Branch name is required"
  echo "Usage: $0 <branch-name>"
  echo "Example: $0 feat/add-login"
  exit 1
fi

# ブランチ名のバリデーション
if [[ ! "$BRANCH_NAME" =~ ^(feat|fix|refactor|docs|chore|perf|test|ci)/ ]]; then
  echo "Warning: Branch name should follow convention: <type>/<description>"
  echo "Types: feat, fix, refactor, docs, chore, perf, test, ci"
  echo "Example: feat/add-login, fix/auth-bug"
  read -p "Continue anyway? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    exit 1
  fi
fi

# develop の最新を取得
echo "Fetching latest from origin/$BASE_BRANCH..."
git fetch origin "$BASE_BRANCH"

# ブランチ作成
echo "Creating branch: $BRANCH_NAME from origin/$BASE_BRANCH"
git checkout -b "$BRANCH_NAME" "origin/$BASE_BRANCH"

echo ""
echo "✅ Branch created: $BRANCH_NAME"
echo "   Base: origin/$BASE_BRANCH"
