#!/bin/bash
# CI Check - .github/workflows/*.yml から run ステップを抽出・実行
# Usage: run.sh [workflow-file] [--list] [--dry-run]
#   workflow-file: 特定のワークフローのみ実行（省略時は全ワークフロー）
#   --list: 実行可能なステップを一覧表示するのみ
#   --dry-run: コマンドを表示するが実行しない
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
WORKFLOW_DIR="$ROOT_DIR/.github/workflows"
LIST_ONLY=false
DRY_RUN=false
TARGET_FILE=""
ERRORS=0
PASSED=0
SKIPPED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

for arg in "$@"; do
  case "$arg" in
    --list) LIST_ONLY=true ;;
    --dry-run) DRY_RUN=true ;;
    *.yml|*.yaml) TARGET_FILE="$arg" ;;
  esac
done

if [ ! -d "$WORKFLOW_DIR" ]; then
  echo -e "${RED}ERROR: $WORKFLOW_DIR not found${NC}"
  exit 1
fi

echo -e "${BOLD}CI Check - Workflow Parser${NC}"
echo "Root: $ROOT_DIR"
echo "================================"
echo ""

# ローカル実行不可のパターン
SKIP_PATTERNS="deploy|firebase|aws |gcloud|docker push|secrets\.|github\.event|GITHUB_TOKEN|GCP_SA_KEY|gh pr |gh issue "

should_skip() {
  echo "$1" | grep -qiE "$SKIP_PATTERNS"
}

# ワークフローファイルを収集
if [ -n "$TARGET_FILE" ]; then
  if [ -f "$WORKFLOW_DIR/$TARGET_FILE" ]; then
    WORKFLOWS=("$WORKFLOW_DIR/$TARGET_FILE")
  elif [ -f "$TARGET_FILE" ]; then
    WORKFLOWS=("$TARGET_FILE")
  else
    echo -e "${RED}ERROR: Workflow file not found: $TARGET_FILE${NC}"
    exit 1
  fi
else
  WORKFLOWS=()
  for f in "$WORKFLOW_DIR"/*.yml "$WORKFLOW_DIR"/*.yaml; do
    [ -f "$f" ] && WORKFLOWS+=("$f")
  done
fi

process_step() {
  local name="$1"
  local run_cmd="$2"
  local wd="$3"
  local step_num="$4"

  [ -z "$run_cmd" ] && return

  local label="${name:-Step $step_num}"
  local exec_dir="$ROOT_DIR"
  [ -n "$wd" ] && exec_dir="$ROOT_DIR/$wd"

  if should_skip "$run_cmd"; then
    if [ "$LIST_ONLY" = true ] || [ "$DRY_RUN" = true ]; then
      echo -e "  ${YELLOW}SKIP${NC} $label (non-local)"
    fi
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if [ "$LIST_ONLY" = true ]; then
    echo -e "  ${GREEN}RUN${NC}  $label"
    [ -n "$wd" ] && echo "       dir: $wd"
    echo "$run_cmd" | while IFS= read -r cmd; do
      [ -n "$cmd" ] && echo "       \$ $cmd"
    done
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${CYAN}DRY${NC}  $label"
    echo "$run_cmd" | while IFS= read -r cmd; do
      [ -n "$cmd" ] && echo "       \$ $cmd"
    done
    return
  fi

  # 実行
  echo -ne "  $label ... "
  if [ ! -d "$exec_dir" ]; then
    echo -e "${YELLOW}SKIP (dir not found: $wd)${NC}"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if (cd "$exec_dir" && eval "$run_cmd") > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}FAIL${NC}"
    ERRORS=$((ERRORS + 1))
    echo -e "    ${RED}--- Error output ---${NC}"
    (cd "$exec_dir" && eval "$run_cmd") 2>&1 | tail -20 | sed 's/^/    /' || true
    echo -e "    ${RED}-------------------${NC}"
  fi
}

for wf in "${WORKFLOWS[@]}"; do
  [ -f "$wf" ] || continue
  WF_NAME=$(basename "$wf")
  DISPLAY_NAME=$(grep -m1 "^name:" "$wf" 2>/dev/null | sed 's/^name:[[:space:]]*//' || echo "$WF_NAME")

  echo -e "${CYAN}=== $DISPLAY_NAME ($WF_NAME) ===${NC}"

  # Python/yq に依存しない簡易 YAML パーサー
  STEP_NUM=0
  CURRENT_NAME=""
  CURRENT_WD=""
  CURRENT_RUN=""
  COLLECTING_RUN=false
  RUN_INDENT=0
  IN_STEPS=false

  while IFS= read -r line || [ -n "$line" ]; do
    # 現在行のインデント数を計算
    stripped="${line#"${line%%[! ]*}"}"
    indent=$(( ${#line} - ${#stripped} ))

    # steps: セクション検出
    if echo "$line" | grep -q "[[:space:]]*steps:"; then
      IN_STEPS=true
      continue
    fi

    # 複数行 run の継続行を収集
    if [ "$COLLECTING_RUN" = true ]; then
      if [ "$indent" -gt "$RUN_INDENT" ]; then
        cmd_line=$(echo "$line" | sed 's/^[[:space:]]*//')
        if [ -n "$cmd_line" ]; then
          if [ -n "$CURRENT_RUN" ]; then
            CURRENT_RUN="${CURRENT_RUN}
${cmd_line}"
          else
            CURRENT_RUN="$cmd_line"
          fi
        fi
        continue
      else
        # インデントが戻った → 収集終了
        COLLECTING_RUN=false
      fi
    fi

    [ "$IN_STEPS" = false ] && continue

    # 新しいステップ（- で始まる）
    if echo "$line" | grep -q "^[[:space:]]*-[[:space:]]"; then
      # 前のステップを処理
      if [ -n "$CURRENT_RUN" ]; then
        STEP_NUM=$((STEP_NUM + 1))
        process_step "$CURRENT_NAME" "$CURRENT_RUN" "$CURRENT_WD" "$STEP_NUM"
      fi

      # リセット
      CURRENT_NAME=""
      CURRENT_WD=""
      CURRENT_RUN=""
      COLLECTING_RUN=false

      # - uses: の場合
      if echo "$line" | grep -q "uses:"; then
        action_name=$(echo "$line" | sed 's/.*uses:[[:space:]]*//')
        SKIPPED=$((SKIPPED + 1))
        if [ "$LIST_ONLY" = true ] || [ "$DRY_RUN" = true ]; then
          echo -e "  ${YELLOW}SKIP${NC} $action_name (GitHub Action)"
        fi
        continue
      fi

      # - name: の場合
      if echo "$line" | grep -q "name:"; then
        CURRENT_NAME=$(echo "$line" | sed 's/.*name:[[:space:]]*//')
      fi

      # - run: (インライン) の場合
      if echo "$line" | grep -q "run:"; then
        run_value=$(echo "$line" | sed 's/.*run:[[:space:]]*//')
        if [ "$run_value" = "|" ] || [ "$run_value" = "|-" ] || [ "$run_value" = "|+" ]; then
          COLLECTING_RUN=true
          RUN_INDENT=$indent
          CURRENT_RUN=""
        else
          CURRENT_RUN="$run_value"
        fi
      fi
      continue
    fi

    # name: (ステップ内のプロパティ)
    if echo "$line" | grep -q "^[[:space:]]*name:"; then
      CURRENT_NAME=$(echo "$line" | sed 's/.*name:[[:space:]]*//')
      continue
    fi

    # working-directory:
    if echo "$line" | grep -q "^[[:space:]]*working-directory:"; then
      CURRENT_WD=$(echo "$line" | sed 's/.*working-directory:[[:space:]]*//')
      continue
    fi

    # run: (ステップ内のプロパティ)
    if echo "$line" | grep -q "^[[:space:]]*run:"; then
      run_value=$(echo "$line" | sed 's/.*run:[[:space:]]*//')
      if [ "$run_value" = "|" ] || [ "$run_value" = "|-" ] || [ "$run_value" = "|+" ]; then
        COLLECTING_RUN=true
        RUN_INDENT=$indent
        CURRENT_RUN=""
      else
        CURRENT_RUN="$run_value"
      fi
      continue
    fi

    # jobs: の新しいジョブでリセット（indent 2 のキー）
    if [ "$indent" -le 2 ] && echo "$line" | grep -qE "^[[:space:]]*[a-z].*:"; then
      if [ -n "$CURRENT_RUN" ]; then
        STEP_NUM=$((STEP_NUM + 1))
        process_step "$CURRENT_NAME" "$CURRENT_RUN" "$CURRENT_WD" "$STEP_NUM"
        CURRENT_RUN=""
        CURRENT_NAME=""
        CURRENT_WD=""
      fi
      IN_STEPS=false
    fi

  done < "$wf"

  # 最後のステップを処理
  if [ -n "$CURRENT_RUN" ]; then
    STEP_NUM=$((STEP_NUM + 1))
    process_step "$CURRENT_NAME" "$CURRENT_RUN" "$CURRENT_WD" "$STEP_NUM"
  fi

  echo ""
done

echo "================================"
if [ "$LIST_ONLY" = true ]; then
  echo "Listed steps from workflows"
elif [ "$DRY_RUN" = true ]; then
  echo "Dry-run complete"
else
  echo -e "Passed:  ${GREEN}$PASSED${NC}"
  echo -e "Failed:  ${RED}$ERRORS${NC}"
  echo -e "Skipped: ${YELLOW}$SKIPPED${NC}"
  echo ""
  [ "$ERRORS" -gt 0 ] && echo -e "${RED}FAILED${NC}" && exit 1
  echo -e "${GREEN}ALL PASSED${NC}"
fi
