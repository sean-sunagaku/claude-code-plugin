#!/bin/bash
# Task Granularity Check (Hybrid: static + claude -p)
#
# Flow:
#   1. Static check → small task → exit 0 (instant, no cost)
#   2. Static check → suspicious → claude -p haiku for LLM evaluation
#
# stdin:  JSON { tool_input: { subject, description } }
# exit 0: allow task creation
# exit 2: block task creation (stderr = reason shown to Claude)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRITERIA_FILE="$SCRIPT_DIR/criteria.md"

input=$(cat)
subject=$(echo "$input" | jq -r '.tool_input.subject // ""')
description=$(echo "$input" | jq -r '.tool_input.description // ""')

# ========== Metrics ==========
desc_word_count=$(echo "$description" | wc -w | tr -d ' ')

has_fe=$(echo "$description $subject" | grep -ciE '(component|hook|UI|画面|表示|フロント|コンポーネント|フック|ページ)' || true)
has_be=$(echo "$description $subject" | grep -ciE '(API|endpoint|route|service|repository|バックエンド|エンドポイント|ルート)' || true)
has_db=$(echo "$description $subject" | grep -ciE '(schema|migration|テーブル|カラム|DB|データベース|マイグレーション|スキーマ)' || true)
layer_count=0
[ "$has_fe" -gt 0 ] && layer_count=$((layer_count + 1))
[ "$has_be" -gt 0 ] && layer_count=$((layer_count + 1))
[ "$has_db" -gt 0 ] && layer_count=$((layer_count + 1))

action_count=$(echo "$description" | grep -coE '(追加|作成|実装|修正|更新|削除|変更|リファクタ|add|create|implement|fix|update|delete|refactor|migrate)' || true)
conjunction_count=$(echo "$subject $description" | grep -ciE '(と共に|および|さらに|に加えて|も合わせて|and also|as well as|additionally)' || true)
bullet_count=$(echo "$description" | grep -cE '^\s*[-*•]\s|^\s*[0-9]+\.' || true)

# ========== Fast Path ==========
if [ "$desc_word_count" -le 40 ] && \
   [ "$layer_count" -le 1 ] && \
   [ "$action_count" -le 2 ] && \
   [ "$conjunction_count" -eq 0 ] && \
   [ "$bullet_count" -le 2 ]; then
  exit 0
fi

# ========== LLM Evaluation ==========
criteria=""
if [ -f "$CRITERIA_FILE" ]; then
  criteria=$(cat "$CRITERIA_FILE")
fi

read -r -d '' SYSTEM_PROMPT <<SYS || true
あなたはタスク粒度の審査官です。与えられたタスクが1つの実装単位として適切かを判定してください。

# 評価基準
${criteria}

# 判定ルール
- 1つの責務・1レイヤーに収まっている → ok
- 密結合な2レイヤー(例: APIとその型定義)は1タスクでもok
- 独立した複数の成果物が混在 → ng、分割案を提示
- 曖昧なスコープ(「機能を実装」等)で中身が不明確 → ng

# 出力形式
JSONのみ回答。コードブロック・説明文は一切不要。
ok の場合: {"ok":true}
ng の場合: {"ok":false,"reason":"このタスクは大きすぎます。理由: ... 分割案: 1. ... 2. ..."}
SYS

llm_result=$(cat <<PROMPT | CLAUDECODE= claude -p \
  --model haiku \
  --system-prompt "$SYSTEM_PROMPT" \
  --allowedTools "" \
  --disable-slash-commands \
  --no-session-persistence \
  2>/dev/null || true
Subject: ${subject}
Description: ${description}
静的解析: 語数=${desc_word_count} レイヤー=${layer_count}(FE:${has_fe}/BE:${has_be}/DB:${has_db}) 動詞=${action_count} 箇条書き=${bullet_count}
PROMPT
)

json_result=$(echo "$llm_result" | sed '/^```/d' | jq -c '.' 2>/dev/null || true)

if [ -n "$json_result" ]; then
  is_ok=$(echo "$json_result" | jq -r '.ok' 2>/dev/null || echo "true")
  if [ "$is_ok" = "false" ]; then
    reason=$(echo "$json_result" | jq -r '.reason // "タスクが大きすぎます"' 2>/dev/null)
    echo "[タスク粒度チェック] $reason 分割案に従ってタスクを細分化してください。" >&2
    exit 2
  fi
fi

exit 0
