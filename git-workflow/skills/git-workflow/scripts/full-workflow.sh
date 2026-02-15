#!/bin/bash
# フルワークフロー: commit → push → PR作成
# Usage: ./full-workflow.sh "<commit message>" "<pr title>" "<pr body>"
#
# commit message と pr title が同じ場合は省略可能:
# ./full-workflow.sh "<message>" "" "<pr body>"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMIT_MESSAGE="${1:-}"
PR_TITLE="${2:-$COMMIT_MESSAGE}"  # 省略時はコミットメッセージを使用
PR_BODY="${3:-}"

CO_AUTHOR="Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
BASE_BRANCH="develop"

# 引数チェック
if [ -z "$COMMIT_MESSAGE" ]; then
  echo "Error: Commit message is required"
  echo "Usage: $0 \"<commit message>\" \"<pr title>\" \"<pr body>\""
  exit 1
fi

# 現在のブランチ確認
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "develop" ]; then
  echo "Error: Cannot run workflow on $CURRENT_BRANCH branch"
  echo "Create a feature branch first: .claude/skills/git-workflow/scripts/create-branch.sh feat/your-feature"
  exit 1
fi

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

# 4. PR作成
echo ""
echo "📬 Creating PR (base: $BASE_BRANCH)..."
gh pr create --base "$BASE_BRANCH" --title "$PR_TITLE" --body "$PR_BODY"

echo ""
echo "✅ Workflow complete!"
