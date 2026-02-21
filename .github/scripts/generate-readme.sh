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
TMP_BETA=$(mktemp)
TMP_INTERNAL=$(mktemp)
TMP_HOOKS=$(mktemp)
trap 'rm -f "$TMP_TABLE" "$TMP_DETAILS" "$TMP_BETA" "$TMP_INTERNAL" "$TMP_HOOKS"' EXIT

# --- Hook プラグインを検出（hooks/ ディレクトリが存在するもの） ---
HOOK_NAMES=()
ALL_PLUGINS=$(jq -c '.plugins[]' "$MARKETPLACE")
while IFS= read -r plugin; do
  name=$(echo "$plugin" | jq -r '.name')
  source=$(echo "$plugin" | jq -r '.source')
  source_dir="$REPO_ROOT/${source#./}"
  if [ -d "$source_dir/hooks" ]; then
    HOOK_NAMES+=("$name")
  fi
done <<< "$ALL_PLUGINS"

# Hook 名を jq フィルタ用に変換
HOOK_FILTER=$(printf '"%s",' "${HOOK_NAMES[@]}" | sed 's/,$//')
HOOK_JQ_FILTER="[${HOOK_FILTER}]"

# --- 公開(stable) / 公開(beta) / 内部 / Hook に分離 ---
HOOK_PLUGINS=$(jq -c --argjson hooks "$HOOK_JQ_FILTER" '[.plugins[] | select(.name as $n | $hooks | index($n) != null)]' "$MARKETPLACE")
STABLE_PLUGINS=$(jq -c --argjson hooks "$HOOK_JQ_FILTER" '[.plugins[] | select((.source | startswith("./.internal") | not) and (.description | startswith("[Beta]") | not) and (.name as $n | $hooks | index($n) == null))]' "$MARKETPLACE")
BETA_PLUGINS=$(jq -c --argjson hooks "$HOOK_JQ_FILTER" '[.plugins[] | select((.source | startswith("./.internal") | not) and (.description | startswith("[Beta]")) and (.name as $n | $hooks | index($n) == null))]' "$MARKETPLACE")
INTERNAL_PLUGINS=$(jq -c --argjson hooks "$HOOK_JQ_FILTER" '[.plugins[] | select((.source | startswith("./.internal")) and (.name as $n | $hooks | index($n) == null))]' "$MARKETPLACE")

STABLE_COUNT=$(echo "$STABLE_PLUGINS" | jq 'length')
BETA_COUNT=$(echo "$BETA_PLUGINS" | jq 'length')
INTERNAL_COUNT=$(echo "$INTERNAL_PLUGINS" | jq 'length')
HOOK_COUNT=$(echo "$HOOK_PLUGINS" | jq 'length')
PUBLIC_COUNT=$((STABLE_COUNT + BETA_COUNT))

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

# --- description から [Beta] プレフィックスを除去 ---
strip_prefix() {
  echo "$1" | sed 's/^\[Beta\] //'
}

# --- Skills テーブル (stable) ---
{
  echo "| Skill | Command | Description | Keywords |"
  echo "|-------|---------|-------------|----------|"
  for i in $(seq 0 $((STABLE_COUNT - 1))); do
    NAME=$(echo "$STABLE_PLUGINS" | jq -r ".[$i].name")
    DESC=$(echo "$STABLE_PLUGINS" | jq -r ".[$i].description")
    KEYWORDS=$(echo "$STABLE_PLUGINS" | jq -r ".[$i].keywords // [] | join(\", \")")
    echo "| **$NAME** | \`/$NAME\` | $DESC | \`$KEYWORDS\` |"
  done
} > "$TMP_TABLE"

# --- Skill Details (stable) ---
{
  for i in $(seq 0 $((STABLE_COUNT - 1))); do
    NAME=$(echo "$STABLE_PLUGINS" | jq -r ".[$i].name")
    SOURCE=$(echo "$STABLE_PLUGINS" | jq -r ".[$i].source")
    DESC=$(echo "$STABLE_PLUGINS" | jq -r ".[$i].description")
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

# --- Beta セクション ---
{
  if [ "$BETA_COUNT" -gt 0 ]; then
    echo "## Beta Skills"
    echo ""
    echo "> 以下のスキルは現在開発中です。動作やインターフェースが変更される可能性があります。"
    echo ""
    echo "| Skill | Command | Description | Keywords |"
    echo "|-------|---------|-------------|----------|"
    for i in $(seq 0 $((BETA_COUNT - 1))); do
      NAME=$(echo "$BETA_PLUGINS" | jq -r ".[$i].name")
      DESC=$(strip_prefix "$(echo "$BETA_PLUGINS" | jq -r ".[$i].description")")
      KEYWORDS=$(echo "$BETA_PLUGINS" | jq -r ".[$i].keywords // [] | join(\", \")")
      echo "| **$NAME** | \`/$NAME\` | $DESC | \`$KEYWORDS\` |"
    done
    echo ""
    for i in $(seq 0 $((BETA_COUNT - 1))); do
      NAME=$(echo "$BETA_PLUGINS" | jq -r ".[$i].name")
      SOURCE=$(echo "$BETA_PLUGINS" | jq -r ".[$i].source")
      DESC=$(strip_prefix "$(echo "$BETA_PLUGINS" | jq -r ".[$i].description")")
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
  fi
} > "$TMP_BETA"

# --- Hooks セクション ---
{
  if [ "$HOOK_COUNT" -gt 0 ]; then
    echo "## Hooks"
    echo ""
    echo "> PostToolUse / PreToolUse 等のフックプラグイン。インストールすると自動的に有効化されます。"
    echo ""
    echo "| Hook | Description | Event | Keywords |"
    echo "|------|-------------|-------|----------|"
    for i in $(seq 0 $((HOOK_COUNT - 1))); do
      NAME=$(echo "$HOOK_PLUGINS" | jq -r ".[$i].name")
      DESC=$(echo "$HOOK_PLUGINS" | jq -r ".[$i].description")
      KEYWORDS=$(echo "$HOOK_PLUGINS" | jq -r ".[$i].keywords // [] | join(\", \")")
      # plugin.json から hook event type を取得
      SOURCE=$(echo "$HOOK_PLUGINS" | jq -r ".[$i].source")
      PLUGIN_JSON="$REPO_ROOT/${SOURCE#./}/plugin.json"
      if [ -f "$PLUGIN_JSON" ]; then
        EVENT=$(jq -r '.hooks | keys[]' "$PLUGIN_JSON" 2>/dev/null | paste -sd'/' - || echo "—")
      else
        EVENT="—"
      fi
      echo "| **$NAME** | $DESC | \`$EVENT\` | \`$KEYWORDS\` |"
    done
    echo ""
    for i in $(seq 0 $((HOOK_COUNT - 1))); do
      NAME=$(echo "$HOOK_PLUGINS" | jq -r ".[$i].name")
      SOURCE=$(echo "$HOOK_PLUGINS" | jq -r ".[$i].source")
      DESC=$(echo "$HOOK_PLUGINS" | jq -r ".[$i].description")
      echo "### $NAME"
      echo ""
      echo "$DESC"
      echo ""
    done
  fi
} > "$TMP_HOOKS"

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
beta = open('$TMP_BETA').read().strip()
internal = open('$TMP_INTERNAL').read().strip()
hooks = open('$TMP_HOOKS').read().strip()
prereqs = open('$PREREQUISITES').read().strip() if __import__('os').path.exists('$PREREQUISITES') else '- **Claude Code** CLI'
badges = '$BADGES'

result = template.replace('{{BADGES}}', badges)
result = result.replace('{{SKILLS_TABLE}}', table)
result = result.replace('{{SKILL_DETAILS}}', details)
result = result.replace('{{BETA_SECTION}}', beta)
result = result.replace('{{HOOKS_SECTION}}', hooks)
result = result.replace('{{INTERNAL_SECTION}}', internal)
result = result.replace('{{PREREQUISITES}}', prereqs)

open('$README', 'w').write(result)
"

echo "README.md generated ($STABLE_COUNT stable, $BETA_COUNT beta, $HOOK_COUNT hooks, $INTERNAL_COUNT internal skills)"
