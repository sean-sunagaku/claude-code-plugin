#!/bin/bash
# CI の完了を待って結果を返す
set -euo pipefail

PR_NUMBER="${1:-}"
MAX_WAIT="${2:-300}"  # デフォルト 5分
INTERVAL=15

if [ -z "$PR_NUMBER" ]; then
  PR_NUMBER=$(gh pr view --json number --jq '.number' 2>/dev/null || true)
  if [ -z "$PR_NUMBER" ]; then
    echo "ERROR: No PR found for current branch."
    exit 1
  fi
fi

echo "Waiting for CI on PR #${PR_NUMBER} (max ${MAX_WAIT}s, polling every ${INTERVAL}s)..."

ELAPSED=0
while [ "$ELAPSED" -lt "$MAX_WAIT" ]; do
  CHECKS_JSON=$(gh pr checks "$PR_NUMBER" --json "name,state" 2>/dev/null || true)

  if [ -z "$CHECKS_JSON" ] || [ "$CHECKS_JSON" = "[]" ]; then
    echo "  [${ELAPSED}s] No checks yet..."
    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))
    continue
  fi

  PENDING=$(echo "$CHECKS_JSON" | jq '[.[] | select(.state == "PENDING" or .state == "QUEUED" or .state == "IN_PROGRESS")] | length')
  FAIL=$(echo "$CHECKS_JSON" | jq '[.[] | select(.state == "FAILURE")] | length')
  PASS=$(echo "$CHECKS_JSON" | jq '[.[] | select(.state == "SUCCESS")] | length')
  TOTAL=$(echo "$CHECKS_JSON" | jq 'length')

  echo "  [${ELAPSED}s] Pass: ${PASS}/${TOTAL}  Fail: ${FAIL}  Pending: ${PENDING}"

  if [ "$PENDING" -eq 0 ]; then
    if [ "$FAIL" -eq 0 ]; then
      echo "RESULT: all_passed"
      exit 0
    else
      echo "RESULT: failed"
      exit 1
    fi
  fi

  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "RESULT: timeout"
exit 2
