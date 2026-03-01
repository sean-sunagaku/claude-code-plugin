#!/bin/bash
# user-story-visualizer - プロジェクト初期化スクリプト
# Usage: bash scripts/init.sh <project-name>
# Example: bash scripts/init.sh miravy

set -e

if [ -z "$1" ]; then
  echo "Error: プロジェクト名を指定してください"
  echo "Usage: bash scripts/init.sh <project-name>"
  exit 1
fi

PROJECT_NAME="$1"
DATE=$(date +%Y-%m-%d)
BASE_DIR="$(pwd)/.claude/user-story-visualizer/${DATE}_${PROJECT_NAME}"

# ディレクトリ構造を作成
mkdir -p "${BASE_DIR}/journeys"
mkdir -p "${BASE_DIR}/insights"
mkdir -p "${BASE_DIR}/visuals"

echo "==================================="
echo "user-story-visualizer initialized"
echo "==================================="
echo ""
echo "Project: ${PROJECT_NAME}"
echo "Date: ${DATE}"
echo ""
echo "Base directory (use this absolute path for all agents):"
echo "${BASE_DIR}"
echo ""
echo "Directory structure created:"
echo "  ${BASE_DIR}/"
echo "  ├── journeys/      <- journey-writer が journey-XX.md を作成"
echo "  ├── insights/      <- insight-analyst が cross-analysis.md, dev-roadmap.md を作成"
echo "  └── visuals/       <- journey-visualizer が journey-map.pen を作成"
echo ""
echo "Note: init.sh はディレクトリのみ作成します。"
echo "      context.md, log.md, research-data.md 等のファイルは"
echo "      各エージェントが Write ツールで作成します。"
