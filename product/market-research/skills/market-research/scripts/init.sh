#!/bin/bash
# market-research プロジェクト初期化スクリプト
# Usage: bash scripts/init.sh <project-name>

set -euo pipefail

PROJECT_NAME="${1:?Usage: bash scripts/init.sh <project-name>}"
DATE=$(date +%Y-%m-%d)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BASE_DIR="${REPO_ROOT}/docs/market-research/${DATE}_${PROJECT_NAME}"

if [ -d "$BASE_DIR" ]; then
  echo "WARNING: Directory already exists: $BASE_DIR"
  echo "Use existing directory? (y/n)"
  read -r REPLY
  if [ "$REPLY" != "y" ]; then
    echo "Aborted."
    exit 1
  fi
fi

mkdir -p "$BASE_DIR"

echo "$BASE_DIR"
