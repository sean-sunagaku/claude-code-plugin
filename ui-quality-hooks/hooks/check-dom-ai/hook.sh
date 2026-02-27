#!/bin/bash
# PostToolUse Hook: AI-powered DOM structure analysis
# Triggered after take_snapshot, analyzes DOM with claude -p (haiku)
# Output: JSON with additionalContext to feed back into main conversation

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract DOM snapshot from tool_response
DOM=$(echo "$INPUT" | jq -r '.tool_response[0].text // empty' 2>/dev/null)

if [ -z "$DOM" ] || [ "$DOM" = "null" ]; then
  exit 0
fi

# Truncate to 8000 chars to stay within token limits
TRUNCATED=$(echo "$DOM" | head -c 8000)

# Analyze with claude -p (haiku for speed/cost)
PROMPT="DOM構造チェッカー。以下のDOMスナップショットを分析し問題を簡潔に報告。

チェック項目:
1. Portal未使用モーダル: fixed/inset-0のオーバーレイがネストされた要素内にある
2. z-index競合: 同スタッキングコンテキスト内で高z-index要素が競合
3. aria-label欠如: button/input/aにアクセシビリティ属性がない
4. label未関連付け: form要素に対応するlabelがない

問題あり→ [DOM ISSUE] プレフィックスで1行ずつ報告。なし→「DOM: 問題なし」とだけ出力。余計な説明不要。

DOM:
${TRUNCATED}"

ANALYSIS=$(claude -p "$PROMPT" --model haiku --no-session-persistence 2>/dev/null || echo "DOM: 分析スキップ")

# Output as JSON with additionalContext so it feeds back into the main conversation
jq -n --arg ctx "$ANALYSIS" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
exit 0
