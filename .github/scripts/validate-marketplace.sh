#!/bin/bash
# validate-marketplace.sh
# marketplace.json のバリデーションと、登録されたプラグイン（スキル・hook）の構造チェック
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

# プラグインタイプ判定: hooks/ があれば "hook"、skills/ があれば "skill"
detect_plugin_type() {
  local plugin_root="$1"
  if [ -d "$plugin_root/hooks" ]; then
    echo "hook"
  elif [ -d "$plugin_root/skills" ]; then
    echo "skill"
  else
    echo "unknown"
  fi
}

# 有効な hook イベント名
VALID_HOOK_EVENTS="PreToolUse PostToolUse Stop Notification SubagentStop"

echo "=== marketplace.json Validation ==="
echo ""

# --- 1. JSON 構文チェック ---
if ! jq empty "$MARKETPLACE" 2>/dev/null; then
  error "marketplace.json is not valid JSON"
  exit 1
fi
ok "Valid JSON"

# --- 2. 必須フィールド ---
for field in name owner; do
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

  # プラグインルートの解決
  PLUGIN_ROOT="$REPO_ROOT/${SOURCE#./}"
  if [ ! -d "$PLUGIN_ROOT" ]; then
    error "$NAME: plugin directory not found at $SOURCE"
    ORPHANED_NAMES+=("$NAME")
    continue
  fi

  # プラグインタイプ判定
  PLUGIN_TYPE=$(detect_plugin_type "$PLUGIN_ROOT")

  case "$PLUGIN_TYPE" in
    # ============================================================
    # Hook プラグインの検証
    # ============================================================
    hook)
      ok "$NAME: detected as hook plugin"

      # --- plugin.json（ルート直下）の検証 ---
      PLUGIN_JSON="$PLUGIN_ROOT/plugin.json"
      if [ ! -f "$PLUGIN_JSON" ]; then
        error "$NAME: plugin.json not found at plugin root"
      else
        ok "$NAME: plugin.json exists"

        if ! jq empty "$PLUGIN_JSON" 2>/dev/null; then
          error "$NAME: plugin.json is not valid JSON"
        else
          # name の一致チェック
          PJ_NAME=$(jq -r '.name // empty' "$PLUGIN_JSON")
          if [ "$PJ_NAME" != "$NAME" ]; then
            error "$NAME: plugin.json name '$PJ_NAME' does not match marketplace name"
          fi

          # version の一致チェック
          PJ_VERSION=$(jq -r '.version // empty' "$PLUGIN_JSON")
          if [ -n "$PJ_VERSION" ] && [ "$PJ_VERSION" != "$VERSION" ]; then
            error "$NAME: version mismatch - plugin.json '$PJ_VERSION' vs marketplace '$VERSION'"
          fi

          # description の存在チェック
          PJ_DESC=$(jq -r '.description // empty' "$PLUGIN_JSON")
          if [ -z "$PJ_DESC" ]; then
            error "$NAME: plugin.json description is missing"
          fi

          # hooks キーの存在チェック
          HOOKS_KEY=$(jq -r '.hooks // empty' "$PLUGIN_JSON")
          if [ -z "$HOOKS_KEY" ] || [ "$HOOKS_KEY" = "null" ]; then
            error "$NAME: plugin.json missing 'hooks' key"
          else
            ok "$NAME: plugin.json has 'hooks' key"

            # hook イベント名の検証
            HOOK_EVENTS=$(jq -r '.hooks | keys[]' "$PLUGIN_JSON" 2>/dev/null || true)
            for event in $HOOK_EVENTS; do
              if ! echo "$VALID_HOOK_EVENTS" | grep -qw "$event"; then
                error "$NAME: unknown hook event '$event' (valid: $VALID_HOOK_EVENTS)"
              else
                ok "$NAME: hook event '$event' is valid"
              fi

              # 各イベントの hooks 配列チェック
              ENTRY_COUNT=$(jq -r ".hooks[\"$event\"] | length" "$PLUGIN_JSON")
              for j in $(seq 0 $((ENTRY_COUNT - 1))); do
                COMMAND=$(jq -r ".hooks[\"$event\"][$j].hooks[0].command // empty" "$PLUGIN_JSON")
                if [ -z "$COMMAND" ]; then
                  error "$NAME: hooks.$event[$j] missing command"
                fi
                HOOK_TYPE=$(jq -r ".hooks[\"$event\"][$j].hooks[0].type // empty" "$PLUGIN_JSON")
                if [ "$HOOK_TYPE" != "command" ]; then
                  error "$NAME: hooks.$event[$j] type must be 'command' (got '$HOOK_TYPE')"
                fi
              done
            done
          fi
        fi
      fi

      # --- hooks/ ディレクトリ内の hook スクリプト検証 ---
      HOOK_FOUND=false
      for hook_dir in "$PLUGIN_ROOT/hooks/"*/; do
        [ -d "$hook_dir" ] || continue
        HOOK_DIR_NAME=$(basename "$hook_dir")
        HOOK_FOUND=true

        # hook スクリプトの存在
        if [ -f "$hook_dir/hook.py" ]; then
          ok "$NAME: hooks/$HOOK_DIR_NAME/hook.py exists"

          # Python 構文チェック
          if python3 -c "import py_compile; py_compile.compile('$hook_dir/hook.py', doraise=True)" 2>/dev/null; then
            ok "$NAME: hooks/$HOOK_DIR_NAME/hook.py syntax OK"
          else
            error "$NAME: hooks/$HOOK_DIR_NAME/hook.py has syntax errors"
          fi
        elif [ -f "$hook_dir/hook.sh" ]; then
          ok "$NAME: hooks/$HOOK_DIR_NAME/hook.sh exists"

          # Bash 構文チェック
          if bash -n "$hook_dir/hook.sh" 2>/dev/null; then
            ok "$NAME: hooks/$HOOK_DIR_NAME/hook.sh syntax OK"
          else
            error "$NAME: hooks/$HOOK_DIR_NAME/hook.sh has syntax errors"
          fi
        else
          error "$NAME: hooks/$HOOK_DIR_NAME/ missing hook.py or hook.sh"
        fi

        # テストの存在確認
        if [ -f "$hook_dir/test.py" ] || [ -f "$hook_dir/test.sh" ]; then
          ok "$NAME: hooks/$HOOK_DIR_NAME/ has test file"
        else
          warn "$NAME: hooks/$HOOK_DIR_NAME/ missing test file (recommended)"
        fi
      done

      if [ "$HOOK_FOUND" = false ]; then
        error "$NAME: hooks/ directory is empty"
      fi
      ;;

    # ============================================================
    # スキルプラグインの検証
    # ============================================================
    skill)
      ok "$NAME: detected as skill plugin"

      # source ディレクトリの存在チェック
      SKILL_DIR="$PLUGIN_ROOT/skills/$NAME"
      if [ ! -d "$SKILL_DIR" ]; then
        error "$NAME: skill directory not found at $SOURCE/skills/$NAME"
        ORPHANED_NAMES+=("$NAME")
        continue
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

      # plugin.json の存在と整合性チェック（.claude-plugin/plugin.json）
      PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"
      if [ ! -f "$PLUGIN_JSON" ]; then
        error "$NAME: .claude-plugin/plugin.json not found"
      else
        ok "$NAME: plugin.json exists"
        if ! jq empty "$PLUGIN_JSON" 2>/dev/null; then
          error "$NAME: plugin.json is not valid JSON"
        else
          # name の一致チェック
          PJ_NAME=$(jq -r '.name // empty' "$PLUGIN_JSON")
          if [ "$PJ_NAME" != "$NAME" ]; then
            error "$NAME: plugin.json name '$PJ_NAME' does not match marketplace name"
          fi

          # version の一致チェック
          PJ_VERSION=$(jq -r '.version // empty' "$PLUGIN_JSON")
          if [ -n "$PJ_VERSION" ] && [ "$PJ_VERSION" != "$VERSION" ]; then
            error "$NAME: version mismatch - plugin.json '$PJ_VERSION' vs marketplace '$VERSION'"
          fi

          # description の存在チェック
          PJ_DESC=$(jq -r '.description // empty' "$PLUGIN_JSON")
          if [ -z "$PJ_DESC" ]; then
            error "$NAME: plugin.json description is missing"
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
            if ! grep -q "^name:" "$agent_file"; then
              error "$NAME: agents/$agent_basename missing 'name' in frontmatter"
            fi
            if ! grep -q "^description:" "$agent_file"; then
              error "$NAME: agents/$agent_basename missing 'description' in frontmatter"
            fi
          done
        fi
      fi
      ;;

    # ============================================================
    # 不明なプラグインタイプ
    # ============================================================
    unknown)
      error "$NAME: plugin directory has neither skills/ nor hooks/ subdirectory"
      ORPHANED_NAMES+=("$NAME")
      ;;
  esac

  echo ""
done

# --- 5. ディレクトリにあるが marketplace.json に未登録のプラグイン ---
echo "=== Unregistered Plugin Check ==="
echo ""

# スキル
for dir in "$REPO_ROOT"/*/skills/*/SKILL.md "$REPO_ROOT"/*/*/skills/*/SKILL.md "$REPO_ROOT"/.internal/*/skills/*/SKILL.md; do
  [ -f "$dir" ] || continue
  SKILL_NAME=$(basename "$(dirname "$dir")")
  if ! jq -r '.plugins[].name' "$MARKETPLACE" | grep -qx "$SKILL_NAME"; then
    warn "$SKILL_NAME: skill exists on disk but not registered in marketplace.json"
  fi
done

# Hook
for dir in "$REPO_ROOT"/*/hooks/*/hook.py "$REPO_ROOT"/*/hooks/*/hook.sh \
           "$REPO_ROOT"/*/*/hooks/*/hook.py "$REPO_ROOT"/*/*/hooks/*/hook.sh \
           "$REPO_ROOT"/.internal/*/hooks/*/hook.py "$REPO_ROOT"/.internal/*/hooks/*/hook.sh; do
  [ -f "$dir" ] || continue
  # hooks/<hook-name>/hook.py → 親の親がプラグインルート
  HOOK_PLUGIN_DIR=$(dirname "$(dirname "$(dirname "$dir")")")
  HOOK_PLUGIN_NAME=$(basename "$HOOK_PLUGIN_DIR")
  if ! jq -r '.plugins[].name' "$MARKETPLACE" | grep -qx "$HOOK_PLUGIN_NAME"; then
    warn "$HOOK_PLUGIN_NAME: hook exists on disk but not registered in marketplace.json"
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
