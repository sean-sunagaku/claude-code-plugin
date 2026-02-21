#!/bin/bash
# user-journey プロジェクト初期化スクリプト
# Usage: bash scripts/init.sh <project-name>
#
# ディレクトリ構造のみ作成する。テンプレートファイルは作成しない。
# ファイルは各エージェントが Write ツールで作成する。

set -euo pipefail

PROJECT_NAME="${1:?Usage: bash scripts/init.sh <project-name>}"
DATE=$(date +%Y-%m-%d)
BASE_DIR="$(pwd)/.claude/user-journey/${DATE}_${PROJECT_NAME}"

if [ -d "$BASE_DIR" ]; then
  echo "Warning: $BASE_DIR already exists"
  exit 1
fi

mkdir -p "$BASE_DIR/journeys"
mkdir -p "$BASE_DIR/insights"

echo "Created: $BASE_DIR"
echo ""
echo "Directories:"
find "$BASE_DIR" -type d | sort | sed "s|$BASE_DIR|  .|"
echo ""
echo "Absolute path (pass this to agents): $BASE_DIR"
