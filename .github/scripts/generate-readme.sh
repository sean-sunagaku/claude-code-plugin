#!/bin/bash
# generate-readme.sh
# テンプレート + marketplace.json + 各 SKILL.md から README.md を生成する
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
TEMPLATE="$REPO_ROOT/.github/templates/README.template.md"
PREREQUISITES="$REPO_ROOT/.github/templates/PREREQUISITES.md"
README="$REPO_ROOT/README.md"
TMP_TABLE=$(mktemp)
TMP_DETAILS=$(mktemp)
TMP_INTERNAL=$(mktemp)
trap 'rm -f "$TMP_TABLE" "$TMP_DETAILS" "$TMP_INTERNAL"' EXIT

# --- 公開スキルと内部スキルを分離 ---
PUBLIC_PLUGINS=$(jq -c '[.plugins[] | select(.source | startswith("./.internal") | not)]' "$MARKETPLACE")
INTERNAL_PLUGINS=$(jq -c '[.plugins[] | select(.source | startswith("./.internal"))]' "$MARKETPLACE")

PUBLIC_COUNT=$(echo "$PUBLIC_PLUGINS" | jq 'length')
INTERNAL_COUNT=$(echo "$INTERNAL_PLUGINS" | jq 'length')

# --- バッジを生成 ---
BADGES="![Skills](https://img.shields.io/badge/skills-${PUBLIC_COUNT}-blue) ![License](https://img.shields.io/badge/license-MIT-green)"

# --- SKILL.md から概要を1行抽出 ---
extract_overview() {
  local skill_md="$1"
  [ -f "$skill_md" ] || return 0
  awk '
    BEGIN { in_front=0; past_front=0; found_heading=0 }
    /^---$/ && !past_front { in_front=!in_front; if(!in_front) past_front=1; next }
    !past_front { next }
    /^# / && !found_heading { found_heading=1; next }
    /^## / && found_heading { exit }
    found_heading && NF { print; exit }
  ' "$skill_md"
}

# --- Skills テーブル ---
{
  echo "| Skill | Command | Description | Keywords |"
  echo "|-------|---------|-------------|----------|"
  for i in $(seq 0 $((PUBLIC_COUNT - 1))); do
    NAME=$(echo "$PUBLIC_PLUGINS" | jq -r ".[$i].name")
    DESC=$(echo "$PUBLIC_PLUGINS" | jq -r ".[$i].description")
    KEYWORDS=$(echo "$PUBLIC_PLUGINS" | jq -r ".[$i].keywords // [] | join(\", \")")
    echo "| **$NAME** | \`/$NAME\` | $DESC | \`$KEYWORDS\` |"
  done
} > "$TMP_TABLE"

# --- Skill Details ---
{
  for i in $(seq 0 $((PUBLIC_COUNT - 1))); do
    NAME=$(echo "$PUBLIC_PLUGINS" | jq -r ".[$i].name")
    SOURCE=$(echo "$PUBLIC_PLUGINS" | jq -r ".[$i].source")
    DESC=$(echo "$PUBLIC_PLUGINS" | jq -r ".[$i].description")

    SKILL_MD="$REPO_ROOT/${SOURCE#./}/skills/$NAME/SKILL.md"
    OVERVIEW=$(extract_overview "$SKILL_MD" 2>/dev/null || echo "")

    echo "### $NAME"
    echo ""
    echo "$DESC"
    if [ -n "$OVERVIEW" ]; then
      echo ""
      echo "$OVERVIEW"
    fi
    echo ""
    echo '```'
    echo "/$NAME"
    echo '```'
    echo ""
  done
} > "$TMP_DETAILS"

# --- Internal セクション ---
{
  if [ "$INTERNAL_COUNT" -gt 0 ]; then
    echo "## Internal Skills"
    echo ""
    echo "> 以下は作者の内部リポジトリ向けスキルです。一般利用者向けではありません。"
    echo ""
    echo "| Skill | Description |"
    echo "|-------|-------------|"
    for i in $(seq 0 $((INTERNAL_COUNT - 1))); do
      NAME=$(echo "$INTERNAL_PLUGINS" | jq -r ".[$i].name")
      DESC=$(echo "$INTERNAL_PLUGINS" | jq -r ".[$i].description" | sed 's/\[Internal\] //')
      echo "| **$NAME** | $DESC |"
    done
  fi
} > "$TMP_INTERNAL"

# --- テンプレートにプレースホルダーを埋め込み ---
python3 -c "
template = open('$TEMPLATE').read()
table = open('$TMP_TABLE').read().strip()
details = open('$TMP_DETAILS').read().strip()
internal = open('$TMP_INTERNAL').read().strip()
prereqs = open('$PREREQUISITES').read().strip() if __import__('os').path.exists('$PREREQUISITES') else '- **Claude Code** CLI'
badges = '$BADGES'

result = template.replace('{{BADGES}}', badges)
result = result.replace('{{SKILLS_TABLE}}', table)
result = result.replace('{{SKILL_DETAILS}}', details)
result = result.replace('{{INTERNAL_SECTION}}', internal)
result = result.replace('{{PREREQUISITES}}', prereqs)

open('$README', 'w').write(result)
"

echo "README.md generated ($PUBLIC_COUNT public, $INTERNAL_COUNT internal skills)"
