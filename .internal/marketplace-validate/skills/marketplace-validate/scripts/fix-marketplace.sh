#!/bin/bash
# fix-marketplace.sh
# marketplace バリデーションエラーを自動修正する
# Usage: fix-marketplace.sh [--dry-run]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../../.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
DRY_RUN=false
FIXED=0

[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

info()  { echo "INFO:  $1"; }
fix()   { echo "FIX:   $1"; FIXED=$((FIXED + 1)); }
skip()  { echo "SKIP:  $1"; }

echo "=== Marketplace Auto-Fix ==="
echo "Repo: $REPO_ROOT"
echo "Mode: $( [ "$DRY_RUN" = true ] && echo 'dry-run' || echo 'fix' )"
echo ""

# --- 1. missing plugin.json の修正 ---
echo "--- Checking plugin.json ---"
PLUGIN_COUNT=$(jq '.plugins | length' "$MARKETPLACE")

for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  NAME=$(jq -r ".plugins[$i].name" "$MARKETPLACE")
  SOURCE=$(jq -r ".plugins[$i].source" "$MARKETPLACE")
  DESC=$(jq -r ".plugins[$i].description" "$MARKETPLACE")
  VERSION=$(jq -r ".plugins[$i].version // \"1.0.0\"" "$MARKETPLACE")
  AUTHOR=$(jq -r ".plugins[$i].author.name // \"sunagaku\"" "$MARKETPLACE")
  KEYWORDS=$(jq -c ".plugins[$i].keywords // []" "$MARKETPLACE")

  PLUGIN_ROOT="$REPO_ROOT/${SOURCE#./}"
  PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"

  if [ -f "$PLUGIN_JSON" ]; then
    # plugin.json の name が marketplace.json と一致するかチェック
    PJ_NAME=$(jq -r '.name // empty' "$PLUGIN_JSON" 2>/dev/null || echo "")
    if [ -n "$PJ_NAME" ] && [ "$PJ_NAME" != "$NAME" ]; then
      info "$NAME: plugin.json name mismatch ('$PJ_NAME' != '$NAME')"
      if [ "$DRY_RUN" = false ]; then
        jq --arg name "$NAME" '.name = $name' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp" \
          && mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"
        fix "$NAME: updated plugin.json name to '$NAME'"
      else
        skip "$NAME: would update plugin.json name (dry-run)"
      fi
    fi

    # plugin.json の version が marketplace.json と一致するかチェック
    PJ_VERSION=$(jq -r '.version // empty' "$PLUGIN_JSON" 2>/dev/null || echo "")
    if [ -n "$PJ_VERSION" ] && [ "$PJ_VERSION" != "$VERSION" ]; then
      info "$NAME: version mismatch - plugin.json '$PJ_VERSION' vs marketplace.json '$VERSION'"
      if [ "$DRY_RUN" = false ]; then
        # plugin.json の version を正とし、marketplace.json を更新
        jq --arg name "$NAME" --arg ver "$PJ_VERSION" \
          '(.plugins[] | select(.name == $name)).version = $ver' "$MARKETPLACE" > "$MARKETPLACE.tmp" \
          && mv "$MARKETPLACE.tmp" "$MARKETPLACE"
        fix "$NAME: updated marketplace.json version to '$PJ_VERSION' (from plugin.json)"
      else
        skip "$NAME: would update marketplace.json version to '$PJ_VERSION' (dry-run)"
      fi
    fi
    continue
  fi

  # plugin.json が存在しない → 生成
  info "$NAME: .claude-plugin/plugin.json not found"

  # ソース (~/.claude/skills/) に plugin.json があればコピー
  LOCAL_PLUGIN="$HOME/.claude/skills/$NAME/.claude-plugin/plugin.json"
  if [ -f "$LOCAL_PLUGIN" ]; then
    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$PLUGIN_ROOT/.claude-plugin"
      cp "$LOCAL_PLUGIN" "$PLUGIN_JSON"
      # name の一致を保証
      jq --arg name "$NAME" '.name = $name' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp" \
        && mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"
      fix "$NAME: copied plugin.json from ~/.claude/skills/$NAME/"
    else
      skip "$NAME: would copy from ~/.claude/skills/$NAME/ (dry-run)"
    fi
    continue
  fi

  # ソースにもない → marketplace.json から生成
  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$PLUGIN_ROOT/.claude-plugin"
    # description から [Internal] [Beta] プレフィックスを除去して plugin.json 用にする
    CLEAN_DESC=$(echo "$DESC" | sed 's/^\[Internal\] //; s/^\[Beta\] //')
    cat > "$PLUGIN_JSON" <<EOJSON
{
  "name": "$NAME",
  "version": "$VERSION",
  "description": "$CLEAN_DESC",
  "author": { "name": "$AUTHOR" },
  "license": "MIT",
  "keywords": $KEYWORDS
}
EOJSON
    fix "$NAME: generated plugin.json from marketplace.json"
  else
    skip "$NAME: would generate plugin.json from marketplace.json (dry-run)"
  fi
done

echo ""

# --- 2. 不正キーの削除 ---
echo "--- Checking unrecognized keys ---"
ALLOWED_KEYS='["name","source","description","version","author","keywords"]'
PLUGIN_COUNT=$(jq '.plugins | length' "$MARKETPLACE")
for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  NAME=$(jq -r ".plugins[$i].name" "$MARKETPLACE")
  EXTRA_KEYS=$(jq -r --argjson allowed "$ALLOWED_KEYS" ".plugins[$i] | keys[] | select(. as \$k | \$allowed | index(\$k) | not)" "$MARKETPLACE")
  if [ -n "$EXTRA_KEYS" ]; then
    for ek in $EXTRA_KEYS; do
      info "$NAME: unrecognized key '$ek'"
      if [ "$DRY_RUN" = false ]; then
        jq --arg name "$NAME" --arg key "$ek" \
          '(.plugins[] | select(.name == $name)) |= del(.[$key])' "$MARKETPLACE" > "$MARKETPLACE.tmp" \
          && mv "$MARKETPLACE.tmp" "$MARKETPLACE"
        fix "$NAME: removed unrecognized key '$ek'"
      else
        skip "$NAME: would remove key '$ek' (dry-run)"
      fi
    done
  fi
done

echo ""

# --- 3. SKILL.md frontmatter の修正 ---
echo "--- Checking SKILL.md frontmatter ---"
for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  NAME=$(jq -r ".plugins[$i].name" "$MARKETPLACE")
  SOURCE=$(jq -r ".plugins[$i].source" "$MARKETPLACE")
  SKILL_DIR="$REPO_ROOT/${SOURCE#./}/skills/$NAME"
  SKILL_MD="$SKILL_DIR/SKILL.md"

  [ ! -f "$SKILL_MD" ] && continue

  if ! grep -q "^name:" "$SKILL_MD"; then
    info "$NAME: SKILL.md missing 'name' in frontmatter"
  fi
  if ! grep -q "^description:" "$SKILL_MD"; then
    info "$NAME: SKILL.md missing 'description' in frontmatter"
  fi
done

echo ""

# --- 4. orphaned marketplace entries (--fix で削除) ---
echo "--- Checking orphaned entries ---"
for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  NAME=$(jq -r ".plugins[$i].name" "$MARKETPLACE")
  SOURCE=$(jq -r ".plugins[$i].source" "$MARKETPLACE")
  SKILL_DIR="$REPO_ROOT/${SOURCE#./}/skills/$NAME"

  if [ ! -d "$SKILL_DIR" ]; then
    info "$NAME: skill directory not found (orphaned entry)"
    if [ "$DRY_RUN" = false ]; then
      jq --arg name "$NAME" '.plugins |= map(select(.name != $name))' "$MARKETPLACE" > "$MARKETPLACE.tmp" \
        && mv "$MARKETPLACE.tmp" "$MARKETPLACE"
      fix "$NAME: removed orphaned entry from marketplace.json"
    else
      skip "$NAME: would remove orphaned entry (dry-run)"
    fi
  fi
done

echo ""

# --- 5. unregistered skills ---
echo "--- Checking unregistered skills ---"
for dir in "$REPO_ROOT"/*/skills/*/SKILL.md "$REPO_ROOT"/.internal/*/skills/*/SKILL.md; do
  [ -f "$dir" ] || continue
  SKILL_NAME=$(basename "$(dirname "$dir")")
  if ! jq -r '.plugins[].name' "$MARKETPLACE" | grep -qx "$SKILL_NAME"; then
    info "$SKILL_NAME: exists on disk but not registered in marketplace.json"
  fi
done

echo ""
echo "==============================="
echo "Fixed: $FIXED"
echo "==============================="
