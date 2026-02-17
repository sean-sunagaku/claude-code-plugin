#!/bin/bash
# detect-prerequisites.sh
# 全スキルのシェルスクリプトをスキャンし、外部ツールの依存を自動検出する
# Usage:
#   detect-prerequisites.sh              # 静的スキャンのみ
#   detect-prerequisites.sh --ai         # 静的スキャン + AI ダブルチェック
#   detect-prerequisites.sh --generate   # PREREQUISITES.md を生成
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT_FILE="$REPO_ROOT/.github/templates/PREREQUISITES.md"
AI_MODE=false
GENERATE_MODE=false

for arg in "$@"; do
  case "$arg" in
    --ai) AI_MODE=true ;;
    --generate) GENERATE_MODE=true ;;
  esac
done

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# tool<TAB>skill のマッピングファイル
MAPPING_FILE="$TMP_DIR/mapping.tsv"
touch "$MAPPING_FILE"

# ────────────────────────────────────────────
# 既知の外部ツール一覧
# スクリプト内でこれらが見つかったら外部依存として記録する
# ────────────────────────────────────────────
KNOWN_TOOLS="claude codex gemini git gh jq python3 python node npx npm pnpm yarn bun lsof docker curl wget pip pip3 cargo brew rustc go java mvn gradle ruby gem kubectl terraform"

# ────────────────────────────────────────────
# ツールの表示名マッピング
# ────────────────────────────────────────────
get_display_name() {
  case "$1" in
    claude)     echo "Claude Code" ;;
    codex)      echo "Codex CLI" ;;
    gemini)     echo "Gemini CLI" ;;
    git)        echo "Git" ;;
    gh)         echo "GitHub CLI (gh)" ;;
    jq)         echo "jq" ;;
    python3)    echo "python3" ;;
    python)     echo "python" ;;
    pnpm)       echo "pnpm" ;;
    lsof)       echo "lsof" ;;
    node)       echo "Node.js" ;;
    npx)        echo "npx" ;;
    npm)        echo "npm" ;;
    docker)     echo "Docker" ;;
    curl)       echo "curl" ;;
    wget)       echo "wget" ;;
    brew)       echo "Homebrew" ;;
    kubectl)    echo "kubectl" ;;
    terraform)  echo "Terraform" ;;
    *)          echo "$1" ;;
  esac
}

# ────────────────────────────────────────────
# スキャン対象ファイルを収集
# ────────────────────────────────────────────
collect_script_files() {
  find "$REPO_ROOT" -path "*/skills/*/scripts/*.sh" -type f 2>/dev/null || true
  find "$REPO_ROOT/.github/scripts" -name "*.sh" -type f 2>/dev/null || true
  find "$REPO_ROOT/.internal" -name "*.sh" -type f 2>/dev/null || true
}

# ────────────────────────────────────────────
# ファイルパスからスキル名を抽出
# ────────────────────────────────────────────
get_skill_name() {
  local file="$1"
  local rel="${file#"$REPO_ROOT"/}"

  if echo "$rel" | grep -qE 'skills/[^/]+/scripts/'; then
    echo "$rel" | sed -E 's|.*skills/([^/]+)/scripts/.*|\1|'
    return
  fi

  if echo "$rel" | grep -q '.github/scripts/'; then
    echo "GitHub Actions"
    return
  fi

  echo "unknown"
}

# ────────────────────────────────────────────
# スクリプトから既知ツールの使用を検出
# コメント行・文字列内を適切に除外
# ────────────────────────────────────────────
detect_tools_in_file() {
  local file="$1"
  local skill_name="$2"

  for tool in $KNOWN_TOOLS; do
    # 自分自身（detect-prerequisites.sh）は除外
    [ "$(basename "$file")" = "detect-prerequisites.sh" ] && return

    # ファイル全体でツール名が含まれるかクイックチェック
    if ! grep -q "$tool" "$file" 2>/dev/null; then
      continue
    fi

    # コメント行を除去してからコマンドとして使われているかチェック
    # パターン: 行頭 / パイプ後 / $() 内 / && || 後 / if/then 後
    local found=false

    # 1. コマンド実行位置にあるか（コメント除去済み）
    if sed 's/#.*//' "$file" | grep -qE "(^| +|[|;&] *|\bthen +|\bdo +|\bif +|\! +|\$\()${tool}( |\$|\"|\)|>|;)" 2>/dev/null; then
      found=true
    fi

    # 2. command -v <tool> のチェックパターン
    if grep -qE "command -v ${tool}" "$file" 2>/dev/null; then
      found=true
    fi

    # 3. which <tool> のチェックパターン
    if grep -qE "which ${tool}" "$file" 2>/dev/null; then
      found=true
    fi

    if [ "$found" = true ]; then
      printf '%s\t%s\n' "$tool" "$skill_name" >> "$MAPPING_FILE"
    fi
  done
}

# ────────────────────────────────────────────
# SKILL.md からツール言及を検出
# コードブロック内のコマンド実行や説明文を対象
# ────────────────────────────────────────────
detect_tools_in_skillmd() {
  local file="$1"
  local skill_name
  skill_name=$(basename "$(dirname "$file")")

  for tool in $KNOWN_TOOLS; do
    if ! grep -qiw "$tool" "$file" 2>/dev/null; then
      continue
    fi

    local found=false

    # 1. コードブロック内でコマンドとして使われている
    #    例: cd packages/web && pnpm run lint
    if sed -n '/^```/,/^```/p' "$file" | grep -qwE "(^| )${tool}( |$)" 2>/dev/null; then
      found=true
    fi

    # 2. インラインコード内でコマンドとして言及（単語境界）
    #    例: `pnpm run test` や `codex exec`
    if grep -qE "\`[^\`]*\b${tool}\b[^\`]*\`" "$file" 2>/dev/null; then
      found=true
    fi

    # 3. スクリプトパス参照（scripts/<tool>-*.sh 等）は除外済み
    #    ツール名そのものがコマンドとして現れるケースのみ

    if [ "$found" = true ]; then
      printf '%s\t%s\n' "$tool" "$skill_name" >> "$MAPPING_FILE"
    fi
  done
}

# ────────────────────────────────────────────
# メインスキャン
# ────────────────────────────────────────────
scan_scripts() {
  # 1. シェルスクリプトをスキャン
  local files
  files=$(collect_script_files)

  while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ "$(basename "$file")" = "detect-prerequisites.sh" ] && continue

    local skill_name
    skill_name=$(get_skill_name "$file")

    detect_tools_in_file "$file" "$skill_name"
  done <<< "$files"

  # 2. SKILL.md をスキャン
  local skill_mds
  skill_mds=$(find "$REPO_ROOT" -path "*/skills/*/SKILL.md" -type f 2>/dev/null || true)

  while IFS= read -r md_file; do
    [ -z "$md_file" ] && continue
    detect_tools_in_skillmd "$md_file"
  done <<< "$skill_mds"

  # 重複を除去
  if [ -s "$MAPPING_FILE" ]; then
    sort -u "$MAPPING_FILE" > "$TMP_DIR/mapping_unique.tsv"
    mv "$TMP_DIR/mapping_unique.tsv" "$MAPPING_FILE"
  fi
}

# ────────────────────────────────────────────
# 結果を表示
# ────────────────────────────────────────────
print_results() {
  echo "=== External Tool Dependencies ==="
  echo ""

  if [ ! -s "$MAPPING_FILE" ]; then
    echo "No external tools detected."
    return
  fi

  local tools
  tools=$(cut -f1 "$MAPPING_FILE" | sort -u)
  local count=0

  printf "%-20s  %s\n" "TOOL" "USED BY"
  printf "%-20s  %s\n" "----" "-------"
  while IFS= read -r tool; do
    [ -z "$tool" ] && continue
    local display
    display=$(get_display_name "$tool")
    local skills
    skills=$(grep "^${tool}	" "$MAPPING_FILE" | cut -f2 | sort -u | awk '{printf "%s%s", sep, $0; sep=", "} END {print ""}')
    printf "%-20s  %s\n" "$display" "$skills"
    count=$((count + 1))
  done <<< "$tools"

  echo ""
  echo "Total: $count external tools detected"
}

# ────────────────────────────────────────────
# PREREQUISITES.md を生成
# ────────────────────────────────────────────
generate_prerequisites() {
  local tools
  tools=$(cut -f1 "$MAPPING_FILE" | sort -u)

  # 必須ツール: 全スキル共通で必要、または GitHub Actions で使用
  # 任意ツール: 特定スキルでのみ使用
  local required_tools="claude git"

  is_required() {
    echo "$required_tools" | grep -qw "$1"
  }

  {
    echo "**Required** (all skills)"
    echo ""
    echo "- **Claude Code** CLI"
    echo "- **Git**"
    echo ""
    echo "**Optional** (skill-specific)"
    echo ""
    while IFS= read -r tool; do
      [ -z "$tool" ] && continue
      is_required "$tool" && continue
      local display
      display=$(get_display_name "$tool")
      local skills
      skills=$(grep "^${tool}	" "$MAPPING_FILE" | cut -f2 | sort -u | awk '{printf "%s%s", sep, $0; sep=" / "} END {print ""}')
      echo "- **${display}** — ${skills}"
    done <<< "$tools"
  } > "$OUTPUT_FILE"

  echo "Generated: $OUTPUT_FILE"
}

# ────────────────────────────────────────────
# AI ダブルチェック
# ────────────────────────────────────────────
ai_check() {
  if ! command -v claude &> /dev/null; then
    echo "SKIP: claude CLI not found, AI check skipped"
    return
  fi

  if [ -n "${CLAUDECODE:-}" ]; then
    echo "SKIP: Claude Code セッション内では --ai は使用できません"
    echo "      ターミナルから直接実行してください:"
    echo "      bash .github/scripts/detect-prerequisites.sh --ai"
    return
  fi

  echo ""
  echo "=== AI Double-Check ==="
  echo ""

  # 全スクリプトの内容を収集
  local all_scripts=""
  local files
  files=$(collect_script_files)
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ "$(basename "$file")" = "detect-prerequisites.sh" ] && continue
    local rel="${file#"$REPO_ROOT"/}"
    all_scripts+="--- ${rel} ---"$'\n'
    all_scripts+="$(cat "$file")"$'\n\n'
  done <<< "$files"

  # 静的スキャン結果
  local detected_list
  detected_list=$(cut -f1 "$MAPPING_FILE" | sort -u | tr '\n' ', ')

  # プロンプトをファイルに書き出し（コマンドライン長制限を回避）
  local prompt_file="$TMP_DIR/ai_prompt.txt"
  cat > "$prompt_file" <<PROMPT_EOF
以下はリポジトリ内の全シェルスクリプトです。
静的スキャンで検出済みの外部ツール: ${detected_list}

これらのスクリプトを分析して、静的スキャンで見落としている可能性のある外部ツール（CLIコマンド）がないか確認してください。
ビルトインのシェルコマンド（echo, grep, sed, awk, cat 等）は除外してください。
見落としがあれば「FOUND: <ツール名> (<使用スキル名>)」形式で出力してください。
見落としがなければ「ALL CLEAR」と出力してください。
簡潔に回答してください。

${all_scripts}
PROMPT_EOF

  local ai_result
  ai_result=$(cat "$prompt_file" | claude -p --permission-mode bypassPermissions 2>/dev/null || echo "AI check failed")
  echo "$ai_result"
}

# ────────────────────────────────────────────
# 実行
# ────────────────────────────────────────────
scan_scripts
print_results

if [ "$GENERATE_MODE" = true ]; then
  echo ""
  generate_prerequisites
fi

if [ "$AI_MODE" = true ]; then
  ai_check
fi
