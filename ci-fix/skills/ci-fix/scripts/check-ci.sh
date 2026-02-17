#!/bin/bash
# CI status checker - PR のCI状態を取得し、失敗時はログを出力する
set -euo pipefail

# --- 引数 / 自動検出 ---
PR_NUMBER="${1:-}"

if [ -z "$PR_NUMBER" ]; then
  # 現在のブランチから PR を自動検出
  PR_NUMBER=$(gh pr view --json number --jq '.number' 2>/dev/null || true)
  if [ -z "$PR_NUMBER" ]; then
    echo "ERROR: No PR found for current branch. Specify PR number as argument."
    exit 1
  fi
fi

echo "=== CI Status for PR #${PR_NUMBER} ==="
echo ""

# --- チェック一覧取得 ---
CHECKS_JSON=$(gh pr checks "$PR_NUMBER" --json "name,state,link,startedAt,completedAt,detailsUrl" 2>/dev/null || true)

if [ -z "$CHECKS_JSON" ] || [ "$CHECKS_JSON" = "[]" ]; then
  echo "STATUS: pending (no checks have run yet)"
  exit 2
fi

# 状態集計
TOTAL=$(echo "$CHECKS_JSON" | jq 'length')
PASS=$(echo "$CHECKS_JSON" | jq '[.[] | select(.state == "SUCCESS")] | length')
FAIL=$(echo "$CHECKS_JSON" | jq '[.[] | select(.state == "FAILURE")] | length')
PENDING=$(echo "$CHECKS_JSON" | jq '[.[] | select(.state == "PENDING" or .state == "QUEUED" or .state == "IN_PROGRESS")] | length')

echo "Total: ${TOTAL}  Pass: ${PASS}  Fail: ${FAIL}  Pending: ${PENDING}"
echo ""

# --- 各チェックの状態 ---
echo "$CHECKS_JSON" | jq -r '.[] | "\(.state)\t\(.name)"' | while IFS=$'\t' read -r state name; do
  case "$state" in
    SUCCESS)     icon="OK" ;;
    FAILURE)     icon="FAIL" ;;
    PENDING|QUEUED|IN_PROGRESS) icon="WAIT" ;;
    *)           icon="??" ;;
  esac
  printf "  %-6s %s\n" "$icon" "$name"
done

echo ""

# --- 失敗がなければ終了 ---
if [ "$FAIL" -eq 0 ] && [ "$PENDING" -eq 0 ]; then
  echo "RESULT: all_passed"
  exit 0
elif [ "$FAIL" -eq 0 ]; then
  echo "RESULT: pending"
  exit 2
fi

# --- 失敗ジョブのログ取得 ---
echo "=== Failed Job Logs ==="
echo ""

FAILED_NAMES=$(echo "$CHECKS_JSON" | jq -r '.[] | select(.state == "FAILURE") | .name')

# PR に紐づく最新の run を取得
BRANCH=$(gh pr view "$PR_NUMBER" --json headRefName --jq '.headRefName')
RUNS_JSON=$(gh run list --branch "$BRANCH" --limit 10 --json databaseId,status,conclusion,name,headSha 2>/dev/null || true)

echo "$FAILED_NAMES" | while IFS= read -r job_name; do
  echo "--- [${job_name}] ---"

  # run ID を特定 (conclusion が failure のもの)
  RUN_ID=$(echo "$RUNS_JSON" | jq -r --arg name "$job_name" \
    '[.[] | select(.conclusion == "failure")] | first | .databaseId // empty')

  if [ -z "$RUN_ID" ]; then
    # ジョブ名で見つからない場合、失敗した run をすべて試す
    FAILED_RUN_IDS=$(echo "$RUNS_JSON" | jq -r '[.[] | select(.conclusion == "failure")] | .[].databaseId')
    for rid in $FAILED_RUN_IDS; do
      LOG=$(gh run view "$rid" --log-failed 2>/dev/null || true)
      if [ -n "$LOG" ]; then
        echo "$LOG"
        break
      fi
    done
  else
    gh run view "$RUN_ID" --log-failed 2>/dev/null || echo "(failed to fetch logs)"
  fi
  echo ""
done

echo "RESULT: failed"
exit 1
