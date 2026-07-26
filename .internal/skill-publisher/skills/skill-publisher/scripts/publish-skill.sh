#!/bin/bash
# publish-skill.sh - スキルを claude-code-plugin の正しい構造にコピーし、marketplace.json に登録する
#
# Usage: publish-skill.sh <source-path> [skill-name] [--internal] [--category CATEGORY]
#   source-path:  SKILL.md があるディレクトリ
#   skill-name:   省略時は source-path のディレクトリ名
#   --internal:   .internal/ 配下に配置（自分のリポジトリ用）
#   --category:   カテゴリ名（product, planning, design, development, review, marketing, agent-toolkit）

set -euo pipefail

# PLUGIN_REPO の解決順:
#   1. 環境変数 PLUGIN_REPO
#   2. このスクリプトが claude-code-plugin リポジトリ内にある場合はそのルート
#   3. $HOME/Repository/claude-code-plugin
resolve_plugin_repo() {
  if [ -n "${PLUGIN_REPO:-}" ]; then
    echo "$PLUGIN_REPO"
    return
  fi
  local d
  d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  while [ "$d" != "/" ]; do
    if [ -f "$d/.claude-plugin/marketplace.json" ]; then
      echo "$d"
      return
    fi
    d="$(dirname "$d")"
  done
  echo "$HOME/Repository/claude-code-plugin"
}

PLUGIN_REPO="$(resolve_plugin_repo)"
MARKETPLACE="$PLUGIN_REPO/.claude-plugin/marketplace.json"

if [ ! -f "$MARKETPLACE" ]; then
  echo "ERROR: claude-code-plugin リポジトリが見つかりません: $PLUGIN_REPO"
  echo "  環境変数 PLUGIN_REPO でリポジトリのパスを指定してください"
  echo "  例: PLUGIN_REPO=~/Repository/claude-code-plugin $0 <source-path> --category design"
  exit 1
fi
INTERNAL=false
BETA=false
MAX_DESC_LEN=150
CATEGORY=""

# 引数パース
POSITIONAL=()
while [ $# -gt 0 ]; do
  case $1 in
    --internal) INTERNAL=true; shift ;;
    --beta) BETA=true; shift ;;
    --category) CATEGORY="$2"; shift 2 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

SOURCE_PATH="${POSITIONAL[0]:?Usage: publish-skill.sh <source-path> [skill-name] [--internal] [--category CATEGORY]}"
SKILL_NAME="${POSITIONAL[1]:-$(basename "$SOURCE_PATH")}"

# 検証
if [ ! -f "$SOURCE_PATH/SKILL.md" ]; then
  echo "ERROR: $SOURCE_PATH/SKILL.md が見つかりません"
  exit 1
fi

# カテゴリ未指定の場合はユーザーに確認を促す
if [ -z "$CATEGORY" ] && [ "$INTERNAL" = false ]; then
  echo "WARNING: --category が指定されていません"
  echo "利用可能なカテゴリ: product, planning, design, development, review, marketing, agent-toolkit"
  read -p "カテゴリを入力してください: " CATEGORY
  if [ -z "$CATEGORY" ]; then
    echo "ERROR: カテゴリは必須です"
    exit 1
  fi
fi

# 配置先の決定
if [ "$INTERNAL" = true ]; then
  TARGET_DIR="$PLUGIN_REPO/.internal/$SKILL_NAME/skills/$SKILL_NAME"
  SOURCE_REF="./.internal/$SKILL_NAME"
else
  TARGET_DIR="$PLUGIN_REPO/$CATEGORY/$SKILL_NAME/skills/$SKILL_NAME"
  SOURCE_REF="./$CATEGORY/$SKILL_NAME"
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

# .claude-plugin/plugin.json がなければ自動生成（CI バリデーション必須）
if [ ! -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]; then
  mkdir -p "$PLUGIN_ROOT/.claude-plugin"

  # SKILL.md から description を抽出し短縮
  AUTO_DESC=$(sed -n '/^description:/,/^[a-z]/{ /^description:/{ s/^description: *>* *//; p; d; }; /^  /{ s/^  *//; p; }; /^[a-z]/q; }' "$SOURCE_PATH/SKILL.md" | tr '\n' ' ' | sed 's/  */ /g; s/ *$//')
  AUTO_DESC=$(echo "$AUTO_DESC" | sed 's/[[:space:]]*Use when:.*//; s/[[:space:]]*Triggers:.*//; s/[[:space:]]*Also use when:.*//; s/ *$//')
  [ -z "$AUTO_DESC" ] && AUTO_DESC="$SKILL_NAME skill plugin"
  # 長い場合は Claude で要約
  if [ ${#AUTO_DESC} -gt $MAX_DESC_LEN ]; then
    SUMMARY_TMP=$(mktemp)
    env -u CLAUDECODE claude -p --model haiku "以下のスキル説明文を${MAX_DESC_LEN}文字以内に要約してください。元の言語を維持し、説明文のみを出力してください。

${AUTO_DESC}" > "$SUMMARY_TMP" 2>/dev/null
    SHORT=$(cat "$SUMMARY_TMP")
    rm -f "$SUMMARY_TMP"
    if [ -n "$SHORT" ] && [ ${#SHORT} -le $MAX_DESC_LEN ] && [ ${#SHORT} -gt 10 ]; then
      AUTO_DESC="$SHORT"
    else
      AUTO_DESC="${AUTO_DESC:0:$((MAX_DESC_LEN - 1))}…"
    fi
  fi

  # keywords を生成
  AUTO_KEYWORDS=$(echo "$SKILL_NAME" | tr '-' '\n' | jq -R . | jq -s '.')

  # plugin.json を生成
  jq -n \
    --arg name "$SKILL_NAME" \
    --arg ver "1.0.0" \
    --arg desc "$AUTO_DESC" \
    --argjson keywords "$AUTO_KEYWORDS" \
    '{
      name: $name,
      version: $ver,
      description: $desc,
      author: { name: "sunagaku" },
      license: "MIT",
      keywords: $keywords
    }' > "$PLUGIN_ROOT/.claude-plugin/plugin.json"

  echo "OK: .claude-plugin/plugin.json を自動生成しました（ソースに存在しなかったため）"
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

# marketplace.json 用に要約: 不要な部分をカットし、MAX_DESC_LEN文字以内に短縮

# Step 1: "Use when:" / "Triggers:" / "Also use when:" 以降をカット
DESCRIPTION=$(echo "$FULL_DESCRIPTION" | sed 's/[[:space:]]*Use when:.*//; s/[[:space:]]*Triggers:.*//; s/[[:space:]]*Also use when:.*//; s/ *$//')
# 空になった場合はフルを使う
[ -z "$DESCRIPTION" ] && DESCRIPTION="$FULL_DESCRIPTION"

# Step 2: まだ長い場合、Claude に要約させる
if [ ${#DESCRIPTION} -gt $MAX_DESC_LEN ]; then
  echo "INFO: description が ${#DESCRIPTION} 文字です（上限: ${MAX_DESC_LEN}）。Claude で要約中..."
  SUMMARY_TMP=$(mktemp)
  env -u CLAUDECODE claude -p --model haiku "以下のスキル説明文を${MAX_DESC_LEN}文字以内に要約してください。
ルール:
- 元の言語（日本語/英語）を維持
- スキルの核心的な機能だけを残す
- 「Use when」「Triggers」は含めない
- 説明文のみを出力（前置きや補足なし）

元の説明文:
${DESCRIPTION}" > "$SUMMARY_TMP" 2>/dev/null
  SUMMARIZED=$(cat "$SUMMARY_TMP")
  rm -f "$SUMMARY_TMP"

  # Claude の出力が有効なら採用
  if [ -n "$SUMMARIZED" ] && [ ${#SUMMARIZED} -le $MAX_DESC_LEN ] && [ ${#SUMMARIZED} -gt 10 ]; then
    DESCRIPTION="$SUMMARIZED"
    echo "OK: Claude が ${#DESCRIPTION} 文字に要約しました"
  else
    # フォールバック: 句点で切る → それでもダメなら切り詰め
    FIRST_SENTENCE=$(echo "$DESCRIPTION" | sed 's/。.*/。/')
    if [ ${#FIRST_SENTENCE} -le $MAX_DESC_LEN ] && [ ${#FIRST_SENTENCE} -gt 10 ]; then
      DESCRIPTION="$FIRST_SENTENCE"
    else
      DESCRIPTION="${DESCRIPTION:0:$((MAX_DESC_LEN - 1))}…"
    fi
    echo "WARN: Claude 要約失敗。フォールバックで ${#DESCRIPTION} 文字に短縮しました"
  fi
fi

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
