#!/bin/bash
# publish-skill.sh - スキルを claude-code-plugin の正しい構造にコピーし、marketplace.json に登録する
#
# Usage: publish-skill.sh <source-path> [skill-name] [--internal]
#   source-path:  SKILL.md があるディレクトリ
#   skill-name:   省略時は source-path のディレクトリ名
#   --internal:   .internal/ 配下に配置（自分のリポジトリ用）

set -euo pipefail

PLUGIN_REPO="/Users/babashunsuke/Desktop/claude-code-plugin"
MARKETPLACE="$PLUGIN_REPO/.claude-plugin/marketplace.json"
INTERNAL=false
BETA=false

# 引数パース
POSITIONAL=()
for arg in "$@"; do
  case $arg in
    --internal) INTERNAL=true ;;
    --beta) BETA=true ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done

SOURCE_PATH="${POSITIONAL[0]:?Usage: publish-skill.sh <source-path> [skill-name] [--internal]}"
SKILL_NAME="${POSITIONAL[1]:-$(basename "$SOURCE_PATH")}"

# 検証
if [ ! -f "$SOURCE_PATH/SKILL.md" ]; then
  echo "ERROR: $SOURCE_PATH/SKILL.md が見つかりません"
  exit 1
fi

# 配置先の決定
if [ "$INTERNAL" = true ]; then
  TARGET_DIR="$PLUGIN_REPO/.internal/$SKILL_NAME/skills/$SKILL_NAME"
  SOURCE_REF="./.internal/$SKILL_NAME"
else
  TARGET_DIR="$PLUGIN_REPO/$SKILL_NAME/skills/$SKILL_NAME"
  SOURCE_REF="./$SKILL_NAME"
fi

# 重複チェック
if [ -d "$TARGET_DIR" ]; then
  echo "WARNING: $TARGET_DIR は既に存在します"
  read -p "上書きしますか? (y/N): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "中止しました"
    exit 0
  fi
  rm -rf "$TARGET_DIR"
fi

# ディレクトリ作成
mkdir -p "$TARGET_DIR"

# SKILL.md をコピー
cp "$SOURCE_PATH/SKILL.md" "$TARGET_DIR/"

# references/ scripts/ assets/ があればコピー
for dir in references scripts assets; do
  if [ -d "$SOURCE_PATH/$dir" ]; then
    cp -r "$SOURCE_PATH/$dir" "$TARGET_DIR/"
  fi
done

# agents/ があれば plugin root 直下にコピー
PLUGIN_ROOT="$(dirname "$(dirname "$TARGET_DIR")")"
if [ -d "$SOURCE_PATH/agents" ]; then
  mkdir -p "$PLUGIN_ROOT/agents"
  cp -r "$SOURCE_PATH/agents/"*.md "$PLUGIN_ROOT/agents/" 2>/dev/null || true
  AGENT_COUNT=$(find "$PLUGIN_ROOT/agents" -name "*.md" | wc -l | tr -d ' ')
  echo "OK: agents/ に ${AGENT_COUNT} 個のサブエージェントをコピーしました"
fi

# .claude-plugin/ があればコピー
SOURCE_BASE="$(dirname "$SOURCE_PATH")"
if [ -d "$SOURCE_BASE/.claude-plugin" ]; then
  mkdir -p "$PLUGIN_ROOT/.claude-plugin"
  cp "$SOURCE_BASE/.claude-plugin/plugin.json" "$PLUGIN_ROOT/.claude-plugin/" 2>/dev/null || true
  echo "OK: .claude-plugin/plugin.json をコピーしました"
elif [ -d "$SOURCE_PATH/../.claude-plugin" ]; then
  mkdir -p "$PLUGIN_ROOT/.claude-plugin"
  cp "$SOURCE_PATH/../.claude-plugin/plugin.json" "$PLUGIN_ROOT/.claude-plugin/" 2>/dev/null || true
  echo "OK: .claude-plugin/plugin.json をコピーしました"
fi

# 不要ファイルを除外
for f in README.md CHANGELOG.md INSTALLATION_GUIDE.md QUICK_REFERENCE.md LICENSE.txt; do
  rm -f "$TARGET_DIR/$f"
done

echo ""
echo "=== Published: $SKILL_NAME ==="
if [ "$INTERNAL" = true ]; then
  echo "    Type: internal"
elif [ "$BETA" = true ]; then
  echo "    Type: beta"
else
  echo "    Type: stable"
fi
echo ""
find "$(dirname "$(dirname "$TARGET_DIR")")" -type f | sort | sed "s|$PLUGIN_REPO/||"

# --- marketplace.json への登録 ---
echo ""

# SKILL.md から description を抽出（YAML frontmatter の description フィールド）
FULL_DESCRIPTION=$(sed -n '/^description:/,/^[a-z]/{ /^description:/{ s/^description: *>* *//; p; d; }; /^  /{ s/^  *//; p; }; /^[a-z]/q; }' "$SOURCE_PATH/SKILL.md" | tr '\n' ' ' | sed 's/  */ /g; s/ *$//')

# marketplace.json 用に要約: "Use when:" / "Triggers:" 以降をカット
DESCRIPTION=$(echo "$FULL_DESCRIPTION" | sed 's/[[:space:]]*Use when:.*//; s/[[:space:]]*Triggers:.*//; s/ *$//')
# 空になった場合はフルを使う
[ -z "$DESCRIPTION" ] && DESCRIPTION="$FULL_DESCRIPTION"

# SKILL.md から name を抽出
SKILL_YAML_NAME=$(grep "^name:" "$SOURCE_PATH/SKILL.md" | head -1 | sed 's/^name: *//')

# plugin.json から version を取得（なければ 1.0.0）
SKILL_VERSION="1.0.0"
for pj_path in "$PLUGIN_ROOT/.claude-plugin/plugin.json" "$SOURCE_BASE/.claude-plugin/plugin.json" "$SOURCE_PATH/../.claude-plugin/plugin.json"; do
  if [ -f "$pj_path" ]; then
    PJ_VER=$(jq -r '.version // empty' "$pj_path" 2>/dev/null || true)
    [ -n "$PJ_VER" ] && SKILL_VERSION="$PJ_VER" && break
  fi
done

# marketplace.json に既に登録済みか確認
if grep -q "\"name\": \"$SKILL_NAME\"" "$MARKETPLACE"; then
  echo "INFO: $SKILL_NAME は marketplace.json に既に登録済みです"
else
  # keywords を生成（skill name をハイフン分割）
  KEYWORDS=$(echo "$SKILL_NAME" | tr '-' '\n' | paste -sd',' - | sed 's/,/", "/g')

  # 最後のエントリの閉じ括弧の後にカンマと新エントリを追加
  # jq があれば使う、なければ sed で追加
  # Beta の場合 description に [Beta] プレフィックスを付与
  if [ "$BETA" = true ] && [[ ! "$DESCRIPTION" =~ ^\[Beta\] ]]; then
    DESCRIPTION="[Beta] $DESCRIPTION"
  fi

  if command -v jq &> /dev/null; then
    if [ "$BETA" = true ]; then
      jq --arg name "$SKILL_NAME" \
         --arg source "$SOURCE_REF" \
         --arg desc "$DESCRIPTION" \
         --arg ver "$SKILL_VERSION" \
         --argjson keywords "$(echo "[\"$KEYWORDS\"]")" \
         '.plugins += [{
           "name": $name,
           "source": $source,
           "description": $desc,
           "version": $ver,
           "status": "beta",
           "author": { "name": "sunagaku" },
           "keywords": $keywords
         }]' "$MARKETPLACE" > "$MARKETPLACE.tmp" && mv "$MARKETPLACE.tmp" "$MARKETPLACE"
    else
      jq --arg name "$SKILL_NAME" \
         --arg source "$SOURCE_REF" \
         --arg desc "$DESCRIPTION" \
         --arg ver "$SKILL_VERSION" \
         --argjson keywords "$(echo "[\"$KEYWORDS\"]")" \
         '.plugins += [{
           "name": $name,
           "source": $source,
           "description": $desc,
           "version": $ver,
           "author": { "name": "sunagaku" },
           "keywords": $keywords
         }]' "$MARKETPLACE" > "$MARKETPLACE.tmp" && mv "$MARKETPLACE.tmp" "$MARKETPLACE"
    fi
    echo "OK: marketplace.json に $SKILL_NAME を登録しました"
  else
    # jq がない場合は手動で追記案を表示
    echo ""
    echo "WARNING: jq がインストールされていないため、marketplace.json の自動登録ができません"
    echo "以下のエントリを .claude-plugin/marketplace.json の plugins 配列に手動で追加してください:"
    echo ""
    echo "    {"
    echo "      \"name\": \"$SKILL_NAME\","
    echo "      \"source\": \"$SOURCE_REF\","
    echo "      \"description\": \"$DESCRIPTION\","
    echo "      \"version\": \"$SKILL_VERSION\","
    echo "      \"author\": { \"name\": \"sunagaku\" },"
    echo "      \"keywords\": [\"$KEYWORDS\"]"
    echo "    }"
  fi
fi

echo ""
echo "Done!"
