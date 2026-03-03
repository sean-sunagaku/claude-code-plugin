#!/bin/bash
# generate-readme.sh
# テンプレート + marketplace.json + 各 SKILL.md からトップ README.md + カテゴリ別 README.md を生成する
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
TEMPLATE="$REPO_ROOT/.github/templates/README.template.md"
PREREQUISITES="$REPO_ROOT/.github/templates/PREREQUISITES.md"
README="$REPO_ROOT/README.md"
TMP_CATEGORY_TABLE=$(mktemp)
TMP_INTERNAL=$(mktemp)
TMP_HOOKS=$(mktemp)
trap 'rm -f "$TMP_CATEGORY_TABLE" "$TMP_INTERNAL" "$TMP_HOOKS"' EXIT

# --- カテゴリ定義（順序と日本語名） ---
# bash 3.x 互換のため associative array を使わず関数で定義
CATEGORY_ORDER=(product planning design development review marketing agent-toolkit)

category_label() {
  case "$1" in
    product)       echo "Product" ;;
    planning)      echo "Planning" ;;
    design)        echo "Design" ;;
    development)   echo "Development" ;;
    review)        echo "Review" ;;
    marketing)     echo "Marketing" ;;
    agent-toolkit) echo "Agent Toolkit" ;;
    *)             echo "$1" ;;
  esac
}

category_desc() {
  case "$1" in
    product)       echo "プロダクトの企画・ユーザーリサーチ・ペルソナ設計・ジャーニーマップ作成" ;;
    planning)      echo "機能検討・技術設計の議論・実装計画の策定" ;;
    design)        echo "UI/UXデザイン・ロゴ作成・デザインバリエーション生成" ;;
    development)   echo "CI/CD・データベース管理・Gitワークフロー・デバッグ・テスト・デプロイ" ;;
    review)        echo "コードレビュー・プランレビュー・UI検証・品質チェック" ;;
    marketing)     echo "アプリ名決定・ASO最適化・スクリーンショット作成・プレビュー動画生成" ;;
    agent-toolkit) echo "エージェントチームの構築・運用・ベストプラクティス" ;;
    *)             echo "" ;;
  esac
}

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
if [ ${#HOOK_NAMES[@]} -gt 0 ]; then
  HOOK_FILTER=$(printf '"%s",' "${HOOK_NAMES[@]}" | sed 's/,$//')
else
  HOOK_FILTER=""
fi
HOOK_JQ_FILTER="[${HOOK_FILTER}]"

# --- 公開 / 内部 / Hook に分離 ---
HOOK_PLUGINS=$(jq -c --argjson hooks "$HOOK_JQ_FILTER" '[.plugins[] | select(.name as $n | $hooks | index($n) != null)]' "$MARKETPLACE")
INTERNAL_PLUGINS=$(jq -c --argjson hooks "$HOOK_JQ_FILTER" '[.plugins[] | select((.source | startswith("./.internal")) and (.name as $n | $hooks | index($n) == null))]' "$MARKETPLACE")
# 公開スキル = 非internal かつ 非hook
PUBLIC_PLUGINS=$(jq -c --argjson hooks "$HOOK_JQ_FILTER" '[.plugins[] | select((.source | startswith("./.internal") | not) and (.name as $n | $hooks | index($n) == null))]' "$MARKETPLACE")

PUBLIC_COUNT=$(echo "$PUBLIC_PLUGINS" | jq 'length')
INTERNAL_COUNT=$(echo "$INTERNAL_PLUGINS" | jq 'length')
HOOK_COUNT=$(echo "$HOOK_PLUGINS" | jq 'length')

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

# --- カテゴリ別にスキルを取得するヘルパー ---
# source パスからカテゴリを導出: "./review/multi-ai-review" → "review"
get_category_plugins() {
  local cat="$1"
  echo "$PUBLIC_PLUGINS" | jq -c --arg cat "$cat" '[.[] | select(.source | ltrimstr("./") | split("/")[0] == $cat)]'
}

# --- カテゴリ概要テーブル（トップ README 用） ---
{
  echo "| Category | Skills | Description |"
  echo "|----------|--------|-------------|"
  for cat in "${CATEGORY_ORDER[@]}"; do
    cat_plugins=$(get_category_plugins "$cat")
    count=$(echo "$cat_plugins" | jq 'length')
    if [ "$count" -eq 0 ]; then
      continue
    fi
    label="$(category_label "$cat")"
    desc="$(category_desc "$cat")"
    echo "| [${label}](./${cat}/) | ${count} skills | ${desc} |"
  done
} > "$TMP_CATEGORY_TABLE"

# --- カテゴリ別 README を生成 ---
for cat in "${CATEGORY_ORDER[@]}"; do
  cat_plugins=$(get_category_plugins "$cat")
  count=$(echo "$cat_plugins" | jq 'length')
  if [ "$count" -eq 0 ]; then
    continue
  fi

  label="$(category_label "$cat")"
  desc="$(category_desc "$cat")"
  cat_dir="$REPO_ROOT/$cat"
  cat_readme="$cat_dir/README.md"

  # カテゴリディレクトリが存在しなければスキップ（ディレクトリ自体がないカテゴリは生成しない）
  if [ ! -d "$cat_dir" ]; then
    continue
  fi

  {
    echo "# ${label}"
    echo ""
    echo "${desc}"
    echo ""
    echo "## Skills"
    echo ""
    echo "| Skill | Command | Description |"
    echo "|-------|---------|-------------|"

    for i in $(seq 0 $((count - 1))); do
      name=$(echo "$cat_plugins" | jq -r ".[$i].name")
      raw_desc=$(echo "$cat_plugins" | jq -r ".[$i].description")
      is_beta=false
      if echo "$raw_desc" | grep -q '^\[Beta\]'; then
        is_beta=true
      fi
      clean_desc=$(strip_prefix "$raw_desc")
      if [ "$is_beta" = true ]; then
        echo "| **${name}** [Beta] | \`/${name}\` | ${clean_desc} |"
      else
        echo "| **${name}** | \`/${name}\` | ${clean_desc} |"
      fi
    done

    echo ""

    # スキル詳細
    for i in $(seq 0 $((count - 1))); do
      name=$(echo "$cat_plugins" | jq -r ".[$i].name")
      source=$(echo "$cat_plugins" | jq -r ".[$i].source")
      raw_desc=$(echo "$cat_plugins" | jq -r ".[$i].description")
      is_beta=false
      if echo "$raw_desc" | grep -q '^\[Beta\]'; then
        is_beta=true
      fi
      clean_desc=$(strip_prefix "$raw_desc")
      skill_md="$REPO_ROOT/${source#./}/skills/$name/SKILL.md"
      overview=$(extract_overview "$skill_md" 2>/dev/null || echo "")

      if [ "$is_beta" = true ]; then
        echo "### ${name} [Beta]"
      else
        echo "### ${name}"
      fi
      echo ""
      echo "${clean_desc}"
      if [ -n "$overview" ]; then
        echo ""
        echo "$overview"
      fi
      echo ""
      echo '```'
      echo "/${name}"
      echo '```'
      echo ""
    done

    echo "---"
    echo ""
    echo "[< Back to top](../README.md)"
  } > "$cat_readme"
done

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
category_table = open('$TMP_CATEGORY_TABLE').read().strip()
internal = open('$TMP_INTERNAL').read().strip()
hooks = open('$TMP_HOOKS').read().strip()
prereqs = open('$PREREQUISITES').read().strip() if __import__('os').path.exists('$PREREQUISITES') else '- **Claude Code** CLI'
badges = '$BADGES'

result = template.replace('{{BADGES}}', badges)
result = result.replace('{{CATEGORY_TABLE}}', category_table)
result = result.replace('{{HOOKS_SECTION}}', hooks)
result = result.replace('{{INTERNAL_SECTION}}', internal)
result = result.replace('{{PREREQUISITES}}', prereqs)

open('$README', 'w').write(result)
"

echo "README.md generated ($PUBLIC_COUNT public, $HOOK_COUNT hooks, $INTERNAL_COUNT internal skills)"
echo "Category READMEs generated for: ${CATEGORY_ORDER[*]}"
