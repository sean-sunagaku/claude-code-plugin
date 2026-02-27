#!/bin/bash
# PostToolUse Hook: AI-powered console message analysis
# Triggered after list_console_messages, analyzes with claude -p (haiku)
# Output: JSON with additionalContext to feed back into main conversation

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract console output from tool_response
CONSOLE=$(echo "$INPUT" | jq -r '.tool_response[0].text // empty' 2>/dev/null)

if [ -z "$CONSOLE" ] || [ "$CONSOLE" = "null" ]; then
  exit 0
fi

# Truncate to 8000 chars
TRUNCATED=$(echo "$CONSOLE" | head -c 8000)

# Analyze with claude -p (haiku for speed/cost)
PROMPT="コンソールメッセージチェッカー。以下のブラウザコンソール出力を分析し問題を分類。

CRITICAL（即報告）:
- Uncaught Error, Unhandled Promise Rejection
- React: Error boundary, Hydration mismatch, Invalid hook call
- 5xx, CORS エラー
- TypeError, ReferenceError

WARNING（報告）:
- deprecated警告, React警告, パフォーマンス警告

IGNORE（無視）:
- favicon.ico/manifest.json の404, CSS preload, HMR/Fast Refresh, Next.js開発警告, console.log/debug

Criticalあり→ [CONSOLE BUG] プレフィックスで報告。Warningのみ→ [CONSOLE WARN] で報告。問題なし→「Console: 重大なエラーなし」とだけ出力。余計な説明不要。

Console output:
${TRUNCATED}"

ANALYSIS=$(claude -p "$PROMPT" --model haiku --no-session-persistence 2>/dev/null || echo "Console: 分析スキップ")

# Output as JSON with additionalContext so it feeds back into the main conversation
jq -n --arg ctx "$ANALYSIS" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
exit 0
