#!/bin/bash
# publish-hook.sh - Hook を claude-code-plugin の正しい構造にコピーし、marketplace.json に登録する
#
# Usage: publish-hook.sh <source-path> <plugin-name> <hook-event> <matcher> [options]
#   source-path:   hook.py/hook.sh があるディレクトリ
#   plugin-name:   プラグイン名（例: agent-teams-log）
#   hook-event:    PostToolUse, PreToolUse, Stop 等
#   matcher:       ツール名マッチャー（例: SendMessage）。空文字 "" なら全ツール対象
#
# Options:
#   --internal           .internal/ 配下に配置
#   --marketplace NAME   marketplace 名 (default: sunagaku-marketplace)
#   --version VER        プラグインバージョン (default: 1.0.0)
#
# command は自動生成される（$HOME ベースのポータブルパス）

set -euo pipefail

PLUGIN_REPO="/Users/babashunsuke/Desktop/claude-code-plugin"
MARKETPLACE_JSON="$PLUGIN_REPO/.claude-plugin/marketplace.json"
INTERNAL=false
MARKETPLACE_NAME="sunagaku-marketplace"
VERSION="1.0.0"

# 引数パース
POSITIONAL=()
while [ $# -gt 0 ]; do
  case $1 in
    --internal) INTERNAL=true; shift ;;
    --marketplace) MARKETPLACE_NAME="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

SOURCE_PATH="${POSITIONAL[0]:?Usage: publish-hook.sh <source-path> <plugin-name> <hook-event> <matcher> [options]}"
PLUGIN_NAME="${POSITIONAL[1]:?Missing plugin-name}"
HOOK_EVENT="${POSITIONAL[2]:?Missing hook-event (PostToolUse, PreToolUse, Stop)}"
MATCHER="${POSITIONAL[3]:?Missing matcher (tool name or empty string)}"

# hook ディレクトリ名（source のディレクトリ名を使う）
HOOK_NAME=$(basename "$SOURCE_PATH")

# hook スクリプトの検出と command 自動生成
CACHE_BASE="\$HOME/.claude/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION/hooks/$HOOK_NAME"

if [ -f "$SOURCE_PATH/hook.py" ]; then
  COMMAND="python3 \"$CACHE_BASE/hook.py\""
elif [ -f "$SOURCE_PATH/hook.sh" ]; then
  COMMAND="bash \"$CACHE_BASE/hook.sh\""
else
  echo "ERROR: $SOURCE_PATH に hook.py も hook.sh も見つかりません"
  exit 1
fi

echo "Generated command (portable):"
echo "  $COMMAND"
echo ""

# 配置先の決定
if [ "$INTERNAL" = true ]; then
  TARGET_ROOT="$PLUGIN_REPO/.internal/$PLUGIN_NAME"
  SOURCE_REF="./.internal/$PLUGIN_NAME"
else
  TARGET_ROOT="$PLUGIN_REPO/$PLUGIN_NAME"
  SOURCE_REF="./$PLUGIN_NAME"
fi

TARGET_HOOKS="$TARGET_ROOT/hooks/$HOOK_NAME"

# 重複チェック
if [ -d "$TARGET_HOOKS" ]; then
  echo "WARNING: $TARGET_HOOKS は既に存在します"
  read -p "上書きしますか? (y/N): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "中止しました"
    exit 0
  fi
  rm -rf "$TARGET_HOOKS"
fi

# ディレクトリ作成 & コピー
mkdir -p "$TARGET_HOOKS"
cp "$SOURCE_PATH"/* "$TARGET_HOOKS/" 2>/dev/null || true

# 不要ファイル除外
for f in README.md CHANGELOG.md; do
  rm -f "$TARGET_HOOKS/$f"
done

echo "OK: hook ファイルを $TARGET_HOOKS にコピーしました"

# --- plugin.json 生成 ---

# docstring から description を抽出（Python の場合）
DESCRIPTION=""
if [ -f "$SOURCE_PATH/hook.py" ]; then
  # triple-quote docstring の最初の行を取得
  DESCRIPTION=$(python3 -c "
import ast, sys
with open('$SOURCE_PATH/hook.py') as f:
    tree = ast.parse(f.read())
doc = ast.get_docstring(tree)
if doc:
    # 最初の段落だけ取得
    first_para = doc.split('\n\n')[0].replace('\n', ' ').strip()
    print(first_para)
" 2>/dev/null || true)
fi

# 取得できなかった場合はプラグイン名から生成
[ -z "$DESCRIPTION" ] && DESCRIPTION="$PLUGIN_NAME hook plugin"

# plugin.json を書き出し（command は $HOME ベースのポータブルパス）
cat > "$TARGET_ROOT/plugin.json" <<EOF
{
  "name": "$PLUGIN_NAME",
  "version": "$VERSION",
  "description": "$DESCRIPTION",
  "hooks": {
    "$HOOK_EVENT": [
      {
        "matcher": "$MATCHER",
        "hooks": [
          {
            "type": "command",
            "command": "$COMMAND"
          }
        ]
      }
    ]
  }
}
EOF

echo "OK: plugin.json を生成しました（$HOME ベースのポータブルパス）"

# --- 配置結果の表示 ---
echo ""
echo "=== Published hook: $PLUGIN_NAME ==="
if [ "$INTERNAL" = true ]; then
  echo "    Type: internal"
else
  echo "    Type: public"
fi
echo "    Marketplace: $MARKETPLACE_NAME"
echo "    Version: $VERSION"
echo "    Command: $COMMAND"
echo ""
find "$TARGET_ROOT" -type f | sort | sed "s|$PLUGIN_REPO/||"

# --- marketplace.json 登録 ---
echo ""

if grep -q "\"name\": \"$PLUGIN_NAME\"" "$MARKETPLACE_JSON"; then
  echo "INFO: $PLUGIN_NAME は marketplace.json に既に登録済みです"
else
  KEYWORDS=$(echo "$PLUGIN_NAME" | tr '-' '\n' | paste -sd',' - | sed 's/,/", "/g')

  if command -v jq &> /dev/null; then
    jq --arg name "$PLUGIN_NAME" \
       --arg source "$SOURCE_REF" \
       --arg desc "$DESCRIPTION" \
       --arg ver "$VERSION" \
       --argjson keywords "$(echo "[\"$KEYWORDS\"]")" \
       '.plugins += [{
         "name": $name,
         "source": $source,
         "description": $desc,
         "version": $ver,
         "author": { "name": "sunagaku" },
         "keywords": $keywords
       }]' "$MARKETPLACE_JSON" > "$MARKETPLACE_JSON.tmp" && mv "$MARKETPLACE_JSON.tmp" "$MARKETPLACE_JSON"
    echo "OK: marketplace.json に $PLUGIN_NAME を登録しました"
  else
    echo "WARNING: jq がないため marketplace.json の自動登録ができません"
    echo "手動で追加してください"
  fi
fi

echo ""
echo "Done!"
