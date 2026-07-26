#!/bin/bash
# package-skill.sh - スキルディレクトリを .skill ファイル（ZIP 形式）にパッケージする
#
# .skill は Claude Design / claude.ai の Skills にそのままアップロードできる配布形式。
# ZIP の中身は <skill-name>/SKILL.md, <skill-name>/references/... という構造になる。
#
# Usage:
#   .github/scripts/package-skill.sh <skill-dir> [output-dir]
#   .github/scripts/package-skill.sh --all [output-dir]
#
# Example:
#   .github/scripts/package-skill.sh design/ios-hig-prototype/skills/ios-hig-prototype
#   .github/scripts/package-skill.sh --all dist
#
# --all は .internal/ 配下（作者用の内部スキル）を対象外にする。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_OUT="$REPO_ROOT/dist"

# frontmatter の許可キー（Anthropic Agent Skills 仕様）
ALLOWED_KEYS="name description license allowed-tools metadata compatibility"

# Claude Code 固有のキー。.skill 仕様には存在しないため、
# リポジトリ側は変更せずパッケージ時のみ除去する。
CC_ONLY_KEYS="disable-model-invocation model context agent"

# validate_skill が「除去対象」として検出したキーを格納する
STRIP_KEYS=""
# description が 1024 文字を超えており、パッケージ時に短縮が必要かどうか
NEEDS_SHRINK=0

usage() {
  echo "Usage: $0 <skill-dir> [output-dir]"
  echo "       $0 --all [output-dir]"
  exit 1
}

# 文字数を数える（日本語を含むためバイト数ではなく文字数で数える）
charlen() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import sys; print(len(sys.argv[1]))' "$1"
  else
    printf '%s' "$1" | LC_ALL=en_US.UTF-8 wc -m | tr -d ' '
  fi
}

# SKILL.md の frontmatter を検証する
validate_skill() {
  local skill_dir="$1"
  local errors=0
  STRIP_KEYS=""
  NEEDS_SHRINK=0

  if [ ! -f "$skill_dir/SKILL.md" ]; then
    echo "  ERROR: SKILL.md が見つかりません"
    return 1
  fi

  local skill_md="$skill_dir/SKILL.md"

  # frontmatter の存在確認
  if [ "$(head -1 "$skill_md")" != "---" ]; then
    echo "  ERROR: YAML frontmatter がありません"
    return 1
  fi

  # frontmatter 範囲を抽出（2行目から次の --- まで）
  local fm
  fm=$(awk 'NR>1 { if ($0 == "---") exit; print }' "$skill_md")

  # トップレベルキーを抽出（インデントなしの "key:" 行）
  local keys
  keys=$(echo "$fm" | grep -E '^[a-zA-Z][a-zA-Z0-9_-]*:' | sed 's/:.*//' || true)

  for k in $keys; do
    if echo "$ALLOWED_KEYS" | tr ' ' '\n' | grep -qx "$k"; then
      continue
    fi
    if echo "$CC_ONLY_KEYS" | tr ' ' '\n' | grep -qx "$k"; then
      echo "  WARN: '$k' は Claude Code 固有のキーです。.skill からは除去します（挙動が変わる可能性あり）"
      STRIP_KEYS="$STRIP_KEYS $k"
      continue
    fi
    echo "  ERROR: frontmatter に不正なキー '$k'（許可: $ALLOWED_KEYS）"
    errors=$((errors + 1))
  done

  # name の検証
  local name
  name=$(echo "$fm" | grep -E '^name:' | head -1 | sed 's/^name: *//' | tr -d '"' | tr -d "'" || true)
  if [ -z "$name" ]; then
    echo "  ERROR: frontmatter に name がありません"
    errors=$((errors + 1))
  else
    if ! echo "$name" | grep -qE '^[a-z0-9-]+$'; then
      echo "  ERROR: name '$name' は kebab-case（英小文字・数字・ハイフン）である必要があります"
      errors=$((errors + 1))
    fi
    local name_len
    name_len=$(charlen "$name")
    if [ "$name_len" -gt 64 ]; then
      echo "  ERROR: name が長すぎます（$name_len 文字 / 上限 64）"
      errors=$((errors + 1))
    fi
    if [ "$name" != "$(basename "$skill_dir")" ]; then
      echo "  WARN: name '$name' がディレクトリ名 '$(basename "$skill_dir")' と一致しません"
    fi
  fi

  # description の検証（複数行 > 記法に対応）
  local desc
  desc=$(echo "$fm" | awk '
    /^description:/ {
      collecting = 1
      line = $0
      sub(/^description:[ \t]*[>|]?-?[ \t]*/, "", line)
      if (line != "") printf "%s ", line
      next
    }
    collecting && /^[ \t]+/ {
      line = $0
      sub(/^[ \t]+/, "", line)
      printf "%s ", line
      next
    }
    collecting { collecting = 0 }
  ' | sed 's/  */ /g; s/^ //; s/ $//')
  if [ -z "$desc" ]; then
    echo "  ERROR: frontmatter に description がありません"
    errors=$((errors + 1))
  else
    local desc_len
    desc_len=$(charlen "$desc")
    if [ "$desc_len" -gt 1024 ]; then
      if command -v python3 >/dev/null 2>&1; then
        echo "  WARN: description が $desc_len 文字（上限 1024）。.skill 側は Triggers 末尾を削って短縮します"
        NEEDS_SHRINK=1
      else
        echo "  ERROR: description が長すぎます（$desc_len 文字 / 上限 1024）。python3 がないため自動短縮できません"
        errors=$((errors + 1))
      fi
    fi
    if echo "$desc" | grep -q '[<>]'; then
      echo "  ERROR: description に山括弧（< >）は使えません。SKILL.md を修正してください"
      errors=$((errors + 1))
    fi
  fi

  return $errors
}

# frontmatter から指定キー（とその継続行）を取り除く
strip_frontmatter_keys() {
  local src="$1"
  local dst="$2"
  local strip="$3"

  awk -v strip="$strip" '
    BEGIN {
      n = split(strip, a, " ")
      for (i = 1; i <= n; i++) if (a[i] != "") drop[a[i]] = 1
    }
    NR == 1 && $0 == "---" { infm = 1; print; next }
    infm && $0 == "---"    { infm = 0; print; next }
    infm {
      if (match($0, /^[a-zA-Z][a-zA-Z0-9_-]*:/)) {
        key = substr($0, 1, RLENGTH - 1)
        skipping = (key in drop) ? 1 : 0
      } else if ($0 !~ /^[ \t]/) {
        skipping = 0
      }
      if (!skipping) print
      next
    }
    { print }
  ' "$src" > "$dst"
}

# description を 1024 文字以内に短縮する（Triggers 末尾から削る）
# 要約や書き換えはせず、末尾の trigger を落とすだけなので意味は壊れない。
shrink_description() {
  local skill_md="$1"

  python3 - "$skill_md" <<'PY'
import re
import sys

LIMIT = 1024
path = sys.argv[1]
text = open(path, encoding="utf-8").read()

m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
if not m:
    sys.exit("frontmatter を解析できません")
fm = m.group(1)

# description ブロック（description: 行 + 続くインデント行）を特定する
lines = fm.split("\n")
start = next((i for i, l in enumerate(lines) if l.startswith("description:")), None)
if start is None:
    sys.exit("description が見つかりません")
end = start + 1
while end < len(lines) and (lines[end].startswith((" ", "\t")) or lines[end].strip() == ""):
    end += 1

first = re.sub(r"^description:[ \t]*[>|]?-?[ \t]*", "", lines[start])
parts = ([first] if first.strip() else []) + [l.strip() for l in lines[start + 1:end] if l.strip()]
desc = " ".join(parts).strip()

if len(desc) <= LIMIT:
    sys.exit(0)

original_len = len(desc)
tm = re.search(r"(Triggers?:\s*)(.*)$", desc, re.DOTALL)
shrunk = None
if tm:
    head, prefix = desc[:tm.start()], tm.group(1)
    items = [t.strip() for t in tm.group(2).split(",") if t.strip()]
    while items:
        cand = (head + prefix + ", ".join(items)).strip()
        if len(cand) <= LIMIT:
            shrunk = cand
            break
        items.pop()
    if shrunk is None and len(head.strip()) <= LIMIT:
        shrunk = head.strip()

if shrunk is None:
    sys.exit(f"description を {LIMIT} 文字以内に短縮できません（{original_len} 文字）")

# YAML ブロックスカラーとして書き戻す
wrapped, line = [], ""
for word in shrunk.split(" "):
    if len(line) + len(word) + 1 > 100:
        wrapped.append("  " + line)
        line = word
    else:
        line = f"{line} {word}".strip()
if line:
    wrapped.append("  " + line)

new_fm = "\n".join(lines[:start] + ["description: >"] + wrapped + lines[end:])
open(path, "w", encoding="utf-8").write(f"---\n{new_fm}\n---\n" + text[m.end():])
print(f"    description: {original_len} 文字 -> {len(shrunk)} 文字", file=sys.stderr)
PY
}

# スキルを .skill にパッケージする
package_skill() {
  local skill_dir="$1"
  local out_dir="$2"

  skill_dir="${skill_dir%/}"
  local skill_name
  skill_name="$(basename "$skill_dir")"

  echo "Packaging: $skill_name"

  if ! validate_skill "$skill_dir"; then
    echo "  FAILED: バリデーションエラーのためスキップしました"
    echo ""
    return 1
  fi

  mkdir -p "$out_dir"
  local out_file="$out_dir/$skill_name.skill"
  rm -f "$out_file"

  # ZIP のエントリを <skill-name>/... にするため親ディレクトリから固める
  local parent
  parent="$(cd "$(dirname "$skill_dir")" && pwd)"
  local tmp_dir=""

  # Claude Code 固有キーの除去 / description の短縮が必要な場合は、
  # 一時コピーに対して適用してから固める（リポジトリ内の SKILL.md は変更しない）
  if [ -n "$(echo "$STRIP_KEYS" | tr -d ' ')" ] || [ "$NEEDS_SHRINK" -eq 1 ]; then
    tmp_dir="$(mktemp -d)"
    cp -R "$skill_dir" "$tmp_dir/$skill_name"
    if [ -n "$(echo "$STRIP_KEYS" | tr -d ' ')" ]; then
      strip_frontmatter_keys "$skill_dir/SKILL.md" "$tmp_dir/$skill_name/SKILL.md" "$STRIP_KEYS"
    fi
    if [ "$NEEDS_SHRINK" -eq 1 ]; then
      if ! shrink_description "$tmp_dir/$skill_name/SKILL.md"; then
        rm -rf "$tmp_dir"
        echo "  FAILED: description を短縮できませんでした"
        echo ""
        return 1
      fi
    fi
    parent="$tmp_dir"
  fi

  ( cd "$parent" && zip -r -q -X "$out_file" "$skill_name" \
      -x "*/__pycache__/*" "*/node_modules/*" "*.pyc" "*/.DS_Store" ".DS_Store" "$skill_name/evals/*" )

  [ -n "$tmp_dir" ] && rm -rf "$tmp_dir"

  local size
  size=$(du -h "$out_file" | cut -f1 | tr -d ' ')
  echo "  OK: $out_file ($size)"
  unzip -Z1 "$out_file" | sed 's/^/    /'
  echo ""
}

[ $# -lt 1 ] && usage

if [ "$1" = "--all" ]; then
  OUT_DIR="${2:-$DEFAULT_OUT}"
  [ "${OUT_DIR#/}" = "$OUT_DIR" ] && OUT_DIR="$REPO_ROOT/$OUT_DIR"
  FAILED=0
  SUCCEEDED=0
  while IFS= read -r md; do
    if package_skill "$(dirname "$md")" "$OUT_DIR"; then
      SUCCEEDED=$((SUCCEEDED + 1))
    else
      FAILED=$((FAILED + 1))
    fi
  done < <(find "$REPO_ROOT" \
              -path "$REPO_ROOT/.git" -prune -o \
              -path "$REPO_ROOT/.internal" -prune -o \
              -path "$REPO_ROOT/dist" -prune -o \
              -name SKILL.md -print | sort)
  echo "Packaged: $SUCCEEDED / Failed: $FAILED"
  [ $FAILED -gt 0 ] && exit 1
  echo "Done."
else
  SKILL_DIR="$1"
  [ "${SKILL_DIR#/}" = "$SKILL_DIR" ] && SKILL_DIR="$REPO_ROOT/$SKILL_DIR"
  OUT_DIR="${2:-$DEFAULT_OUT}"
  [ "${OUT_DIR#/}" = "$OUT_DIR" ] && OUT_DIR="$REPO_ROOT/$OUT_DIR"
  package_skill "$SKILL_DIR" "$OUT_DIR"
fi
