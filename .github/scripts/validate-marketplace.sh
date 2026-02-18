#!/bin/bash
# validate-marketplace.sh
# marketplace.json のバリデーションと、登録されたスキルの構造チェック
# Usage: validate-marketplace.sh [--fix]
#   --fix: ディレクトリが存在しないエントリを marketplace.json から自動削除
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
ERRORS=0
WARNINGS=0
FIX_MODE=false
ORPHANED_NAMES=()

[ "${1:-}" = "--fix" ] && FIX_MODE=true

error() { echo "ERROR: $1"; ERRORS=$((ERRORS + 1)); }
warn()  { echo "WARN:  $1"; WARNINGS=$((WARNINGS + 1)); }
ok()    { echo "OK:    $1"; }

echo "=== marketplace.json Validation ==="
echo ""

# --- 1. JSON 構文チェック ---
if ! jq empty "$MARKETPLACE" 2>/dev/null; then
  error "marketplace.json is not valid JSON"
  exit 1
fi
ok "Valid JSON"

# --- 2. 必須フィールド ---
for field in name version description owner; do
  if [ "$(jq -r ".$field // empty" "$MARKETPLACE")" = "" ]; then
    error "Top-level field '$field' is missing"
  else
    ok "Top-level '$field' exists"
  fi
done

# --- 3. plugins 配列の存在 ---
PLUGIN_COUNT=$(jq '.plugins | length' "$MARKETPLACE")
if [ "$PLUGIN_COUNT" -eq 0 ]; then
  error "plugins array is empty"
else
  ok "plugins array has $PLUGIN_COUNT entries"
fi

echo ""
echo "=== Plugin Entry Validation ==="
echo ""

# --- 4. 各プラグインの検証 ---
NAMES_SEEN=()
for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  NAME=$(jq -r ".plugins[$i].name" "$MARKETPLACE")
  SOURCE=$(jq -r ".plugins[$i].source" "$MARKETPLACE")
  DESC=$(jq -r ".plugins[$i].description" "$MARKETPLACE")
  VERSION=$(jq -r ".plugins[$i].version" "$MARKETPLACE")
  KEYWORDS=$(jq -r ".plugins[$i].keywords // empty" "$MARKETPLACE")

  echo "--- [$NAME] ---"

  # スキーマ不正キーチェック（許可: name, source, description, version, author, keywords）
  ALLOWED_KEYS='["name","source","description","version","author","keywords"]'
  EXTRA_KEYS=$(jq -r --argjson allowed "$ALLOWED_KEYS" ".plugins[$i] | keys[] | select(. as \$k | \$allowed | index(\$k) | not)" "$MARKETPLACE")
  if [ -n "$EXTRA_KEYS" ]; then
    for ek in $EXTRA_KEYS; do
      error "$NAME: unrecognized key '$ek' (schema only allows: name, source, description, version, author, keywords)"
    done
  fi

  # 名前の重複チェック
  for seen in "${NAMES_SEEN[@]+"${NAMES_SEEN[@]}"}"; do
    if [ "$seen" = "$NAME" ]; then
      error "Duplicate plugin name: $NAME"
    fi
  done
  NAMES_SEEN+=("$NAME")

  # 必須フィールド
  [ -z "$NAME" ]    && error "plugins[$i].name is missing"
  [ -z "$SOURCE" ]  && error "plugins[$i].source is missing"
  [ -z "$DESC" ]    && error "plugins[$i].description is missing"
  [ -z "$VERSION" ] && error "plugins[$i].version is missing"

  # [Beta] プレフィックスの確認
  if [[ "$DESC" =~ ^\[Beta\] ]]; then
    ok "$NAME: marked as [Beta]"
  fi

  # description の長さ
  DESC_LEN=${#DESC}
  if [ "$DESC_LEN" -lt 10 ]; then
    error "$NAME: description is too short ($DESC_LEN chars, min 10)"
  fi

  # source ディレクトリの存在チェック
  SKILL_DIR="$REPO_ROOT/$SOURCE/skills/$NAME"
  if [ ! -d "$SKILL_DIR" ]; then
    # internal の場合は source が ./.internal/<name> なのでパス調整
    SKILL_DIR_ALT="$REPO_ROOT/${SOURCE#./}/skills/$NAME"
    if [ ! -d "$SKILL_DIR_ALT" ]; then
      error "$NAME: skill directory not found at $SOURCE/skills/$NAME"
      ORPHANED_NAMES+=("$NAME")
      continue
    fi
    SKILL_DIR="$SKILL_DIR_ALT"
  fi
  ok "$NAME: skill directory exists"

  # SKILL.md の存在
  if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
    error "$NAME: SKILL.md not found in $SKILL_DIR"
    continue
  fi
  ok "$NAME: SKILL.md exists"

  # SKILL.md frontmatter チェック
  if ! grep -q "^name:" "$SKILL_DIR/SKILL.md"; then
    error "$NAME: SKILL.md missing 'name' in frontmatter"
  fi
  if ! grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
    error "$NAME: SKILL.md missing 'description' in frontmatter"
  fi

  # references/ 内のファイルが SKILL.md から参照されているか
  if [ -d "$SKILL_DIR/references" ]; then
    for ref in "$SKILL_DIR/references/"*; do
      [ -f "$ref" ] || continue
      ref_basename=$(basename "$ref")
      if ! grep -q "$ref_basename" "$SKILL_DIR/SKILL.md"; then
        warn "$NAME: references/$ref_basename is not referenced from SKILL.md"
      fi
    done
  fi

  # plugin.json の存在と整合性チェック
  PLUGIN_ROOT="$REPO_ROOT/${SOURCE#./}"
  PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"
  if [ ! -f "$PLUGIN_JSON" ]; then
    error "$NAME: .claude-plugin/plugin.json not found"
  else
    ok "$NAME: plugin.json exists"
    # plugin.json が valid JSON かチェック
    if ! jq empty "$PLUGIN_JSON" 2>/dev/null; then
      error "$NAME: plugin.json is not valid JSON"
    else
      # name の一致チェック
      PJ_NAME=$(jq -r '.name // empty' "$PLUGIN_JSON")
      if [ "$PJ_NAME" != "$NAME" ]; then
        error "$NAME: plugin.json name '$PJ_NAME' does not match marketplace.json name '$NAME'"
      fi

      # version の一致チェック
      PJ_VERSION=$(jq -r '.version // empty' "$PLUGIN_JSON")
      if [ -n "$PJ_VERSION" ] && [ "$PJ_VERSION" != "$VERSION" ]; then
        error "$NAME: version mismatch - plugin.json '$PJ_VERSION' vs marketplace.json '$VERSION'"
      fi
    fi
  fi

  # agents/ のバリデーション（plugin root 直下）
  if [ -d "$PLUGIN_ROOT/agents" ]; then
    AGENT_FILES=("$PLUGIN_ROOT/agents/"*.md)
    if [ -f "${AGENT_FILES[0]}" ]; then
      AGENT_COUNT=${#AGENT_FILES[@]}
      ok "$NAME: agents/ has $AGENT_COUNT agent(s)"
      for agent_file in "${AGENT_FILES[@]}"; do
        agent_basename=$(basename "$agent_file")
        # frontmatter の name と description チェック
        if ! grep -q "^name:" "$agent_file"; then
          error "$NAME: agents/$agent_basename missing 'name' in frontmatter"
        fi
        if ! grep -q "^description:" "$agent_file"; then
          error "$NAME: agents/$agent_basename missing 'description' in frontmatter"
        fi
      done
    fi
  fi

  echo ""
done

# --- 5. ディレクトリにあるがmarketplace.jsonに未登録のスキル ---
echo "=== Unregistered Skill Check ==="
echo ""
for dir in "$REPO_ROOT"/*/skills/*/SKILL.md "$REPO_ROOT"/.internal/*/skills/*/SKILL.md; do
  [ -f "$dir" ] || continue
  SKILL_NAME=$(basename "$(dirname "$dir")")
  if ! jq -r '.plugins[].name' "$MARKETPLACE" | grep -qx "$SKILL_NAME"; then
    warn "$SKILL_NAME: exists on disk but not registered in marketplace.json"
  fi
done

# --- 6. Auto-fix: ディレクトリが存在しないエントリを削除 ---
if [ "$FIX_MODE" = true ] && [ ${#ORPHANED_NAMES[@]} -gt 0 ]; then
  echo ""
  echo "=== Auto-fix: Removing orphaned entries ==="
  echo ""
  for orphan in "${ORPHANED_NAMES[@]}"; do
    echo "REMOVING: $orphan (directory not found)"
    jq --arg name "$orphan" '.plugins |= map(select(.name != $name))' "$MARKETPLACE" > "$MARKETPLACE.tmp" \
      && mv "$MARKETPLACE.tmp" "$MARKETPLACE"
  done
  REMOVED=${#ORPHANED_NAMES[@]}
  echo ""
  echo "Removed $REMOVED orphaned entries from marketplace.json"
  # エラー数を調整（削除したエントリ分のエラーは解消済み）
  ERRORS=$((ERRORS - REMOVED))
fi

# --- Result ---
echo ""
echo "==============================="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo "==============================="

if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED"
  exit 1
else
  echo "PASSED"
fi
