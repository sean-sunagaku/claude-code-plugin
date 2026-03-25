#!/bin/bash
# フルワークフロー: (必要なら新ブランチ作成 →) commit → push → PR作成
# Usage: ./full-workflow.sh "<commit message>" "<pr title>" "<pr body>" [branch-name]
#
# commit message と pr title が同じ場合は省略可能:
# ./full-workflow.sh "<message>" "" "<pr body>"
#
# 4番目の引数で新ブランチ名を指定可能（省略時は現在のブランチを使用）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMIT_MESSAGE="${1:-}"
PR_TITLE="${2:-$COMMIT_MESSAGE}"  # 省略時はコミットメッセージを使用
PR_BODY="${3:-}"
NEW_BRANCH="${4:-}"

CO_AUTHOR="Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

# リモートの最新を取得
echo "🔄 Fetching latest from origin..."
git fetch origin

# ベースブランチを自動検出（develop があれば develop、なければ main）
if git rev-parse --verify origin/develop >/dev/null 2>&1; then
  BASE_BRANCH="develop"
else
  BASE_BRANCH="main"
fi
echo "   Base branch: $BASE_BRANCH"

# 引数チェック
if [ -z "$COMMIT_MESSAGE" ]; then
  echo "Error: Commit message is required"
  echo "Usage: $0 \"<commit message>\" \"<pr title>\" \"<pr body>\" [branch-name]"
  exit 1
fi

# 現在のブランチ確認
CURRENT_BRANCH=$(git branch --show-current)

# main/develop にいる場合、または新ブランチ名が指定された場合 → 新ブランチを作成
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "develop" ] || [ -n "$NEW_BRANCH" ]; then
  if [ -z "$NEW_BRANCH" ]; then
    echo "Error: Cannot run workflow on $CURRENT_BRANCH branch"
    echo "Specify a branch name as 4th argument, or create a branch first"
    echo "Usage: $0 \"<commit message>\" \"<pr title>\" \"<pr body>\" feat/your-feature"
    exit 1
  fi

  echo ""
  echo "🌿 Creating new branch from latest $BASE_BRANCH..."

  # 未コミットの変更がある場合は stash
  HAS_CHANGES=false
  if ! git diff --quiet || ! git diff --cached --quiet; then
    HAS_CHANGES=true
    echo "   Stashing uncommitted changes..."
    git stash push -m "full-workflow: temp stash for branch switch"
  fi

  # ベースブランチを最新に
  git checkout "$BASE_BRANCH"
  git pull origin "$BASE_BRANCH"

  # 新ブランチ作成
  git checkout -b "$NEW_BRANCH"
  CURRENT_BRANCH="$NEW_BRANCH"

  # stash を戻す
  if [ "$HAS_CHANGES" = true ]; then
    echo "   Restoring stashed changes..."
    git stash pop
  fi

  echo "   ✅ Branch created: $NEW_BRANCH (from latest $BASE_BRANCH)"
fi

echo ""
echo "📋 Full Workflow: $CURRENT_BRANCH"
echo "================================"
echo ""

# 1. ステージされた変更を確認
if git diff --cached --quiet; then
  echo "⚠️  No staged changes. Staging all modified files..."
  git add -A
fi

# 2. コミット
echo "📝 Creating commit..."
git commit -m "$COMMIT_MESSAGE

$CO_AUTHOR"

# 3. Push
echo ""
echo "🚀 Pushing to origin/$CURRENT_BRANCH..."
git push -u origin "$CURRENT_BRANCH"

# 4. PR作成（既存PRがなければ作成）
echo ""
EXISTING_PR=$(gh pr list --head "$CURRENT_BRANCH" --base "$BASE_BRANCH" --json number --jq '.[0].number' 2>/dev/null || echo "")
if [ -n "$EXISTING_PR" ]; then
  echo "📬 PR #$EXISTING_PR already exists. Pushed updates."
  gh pr view "$EXISTING_PR" --web 2>/dev/null || true
else
  echo "📬 Creating PR (base: $BASE_BRANCH)..."
  gh pr create --base "$BASE_BRANCH" --title "$PR_TITLE" --body "$PR_BODY"
fi

echo ""
echo "✅ Workflow complete!"
