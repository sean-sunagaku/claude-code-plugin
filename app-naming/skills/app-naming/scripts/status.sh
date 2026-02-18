#!/bin/bash
# app-naming: プロジェクトの進捗状況を表示
# Usage: bash scripts/status.sh [project-dir]
#
# project-dir 省略時は .claude/app-naming/ 配下の全プロジェクトを表示

set -euo pipefail

BASE_DIR="${HOME}/.claude/app-naming"

show_project() {
  local dir="$1"
  local name=$(basename "$dir")

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ${name}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  [ -f "${dir}/context.md" ] && echo "  context.md: ✓" || echo "  context.md: ✗ (未作成)"
  [ -f "${dir}/SUMMARY.md" ] && echo "  SUMMARY.md: ✓" || echo "  SUMMARY.md: ✗"

  local rounds=($(ls -d "${dir}"/round-* 2>/dev/null | sort -V))
  if [ ${#rounds[@]} -eq 0 ]; then
    echo "  Rounds: なし"
    return
  fi

  echo "  Rounds: ${#rounds[@]}"
  echo ""

  for round in "${rounds[@]}"; do
    local round_name=$(basename "$round")
    local has_context="✗"
    local has_log="✗"
    local has_candidates="✗"
    local candidate_count=0

    if [ -f "${round}/context.md" ]; then
      local size=$(wc -c < "${round}/context.md" | tr -d ' ')
      [ "$size" -gt 200 ] && has_context="✓" || has_context="△ (テンプレートのみ)"
    fi

    if [ -f "${round}/log.md" ]; then
      local size=$(wc -c < "${round}/log.md" | tr -d ' ')
      [ "$size" -gt 300 ] && has_log="✓" || has_log="△ (テンプレートのみ)"
    fi

    if [ -f "${round}/candidates.md" ]; then
      local size=$(wc -c < "${round}/candidates.md" | tr -d ' ')
      [ "$size" -gt 400 ] && has_candidates="✓" || has_candidates="△ (テンプレートのみ)"
      # 候補数をカウント（| No. | 以外の行で | 数字 | のパターン）
      candidate_count=$(grep -c "^| [0-9]" "${round}/candidates.md" 2>/dev/null || echo "0")
    fi

    echo "  ${round_name}/"
    echo "    context:    ${has_context}"
    echo "    log:        ${has_log}"
    echo "    candidates: ${has_candidates} (${candidate_count} entries)"
    echo ""
  done

  # final ディレクトリ
  if [ -d "${dir}/final" ]; then
    echo "  final/"
    [ -f "${dir}/final/report.md" ] && echo "    report: ✓" || echo "    report: ✗"
  fi
}

if [ $# -ge 1 ]; then
  show_project "$1"
else
  if [ ! -d "$BASE_DIR" ]; then
    echo "No app-naming projects found."
    echo "Run: bash scripts/init.sh <project-name>"
    exit 0
  fi

  projects=($(ls -d "${BASE_DIR}"/*/ 2>/dev/null || true))
  if [ ${#projects[@]} -eq 0 ]; then
    echo "No app-naming projects found."
    exit 0
  fi

  echo ""
  echo "  App Naming Projects"
  echo ""

  for proj in "${projects[@]}"; do
    show_project "$proj"
    echo ""
  done
fi
