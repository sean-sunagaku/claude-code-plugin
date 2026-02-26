#!/bin/bash
# validate-skill.sh - スキルの構造を検証する
#
# Usage: validate-skill.sh <skill-path>

set -euo pipefail

SKILL_PATH="${1:?Usage: validate-skill.sh <skill-path>}"
ERRORS=0

echo "=== Validating: $SKILL_PATH ==="
echo ""

# 1. SKILL.md の存在
if [ ! -f "$SKILL_PATH/SKILL.md" ]; then
  echo "FAIL: SKILL.md が見つかりません"
  exit 1
fi
echo "OK: SKILL.md exists"

# 2. frontmatter の name
if ! grep -q "^name:" "$SKILL_PATH/SKILL.md"; then
  echo "FAIL: YAML frontmatter に 'name' がありません"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: name field found"
fi

# 3. frontmatter の description
if ! grep -q "^description:" "$SKILL_PATH/SKILL.md"; then
  echo "FAIL: YAML frontmatter に 'description' がありません"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: description field found"
fi

# 4. description の長さチェック（150文字推奨）
DESC_RAW=$(sed -n '/^description:/,/^[a-z]/{ /^description:/{ s/^description: *>* *//; p; d; }; /^  /{ s/^  *//; p; }; /^[a-z]/q; }' "$SKILL_PATH/SKILL.md" | tr '\n' ' ' | sed 's/  */ /g; s/ *$//')
DESC_LEN=${#DESC_RAW}
MAX_DESC_LEN=150
if [ "$DESC_LEN" -gt "$MAX_DESC_LEN" ]; then
  echo "WARN: description が ${DESC_LEN} 文字です（推奨: ${MAX_DESC_LEN}文字以内）。publish 時に自動短縮されます"
elif [ "$DESC_LEN" -gt 0 ]; then
  echo "OK: description length ${DESC_LEN} chars"
fi

# 5. references/ 内のファイルが SKILL.md から参照されているか
if [ -d "$SKILL_PATH/references" ]; then
  for ref in "$SKILL_PATH/references/"*; do
    basename_ref=$(basename "$ref")
    if ! grep -q "$basename_ref" "$SKILL_PATH/SKILL.md"; then
      echo "WARN: references/$basename_ref が SKILL.md から参照されていません"
    else
      echo "OK: references/$basename_ref is referenced"
    fi
  done
fi

# 5. 不要ファイルの検出
for f in README.md CHANGELOG.md INSTALLATION_GUIDE.md QUICK_REFERENCE.md; do
  if [ -f "$SKILL_PATH/$f" ]; then
    echo "WARN: 不要ファイル $f が含まれています（公開時に除外されます）"
  fi
done

echo ""
if [ $ERRORS -gt 0 ]; then
  echo "RESULT: $ERRORS error(s) found"
  exit 1
else
  echo "RESULT: Validation passed"
fi
