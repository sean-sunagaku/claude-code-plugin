#!/bin/bash
# logo-design: プロジェクトの進捗状況を表示
# Usage: bash scripts/status.sh [project-dir]
#
# project-dir 省略時は .claude/logo-design/ 配下の全プロジェクトを表示

set -euo pipefail

BASE_DIR="${HOME}/.claude/logo-design"

show_project() {
  local dir="$1"
  local name=$(basename "$dir")

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ${name}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ -f "${dir}/context.md" ]; then
    echo "  context.md: ✓"
  else
    echo "  context.md: ✗ (未作成)"
  fi

  [ -f "${dir}/SUMMARY.md" ] && echo "  SUMMARY.md: ✓" || echo "  SUMMARY.md: ✗"

  local steps=($(ls -d "${dir}"/step-* 2>/dev/null | sort -V))
  if [ ${#steps[@]} -eq 0 ]; then
    echo "  Steps: なし"
    return
  fi

  echo "  Steps: ${#steps[@]}"
  echo ""

  for step in "${steps[@]}"; do
    local step_name=$(basename "$step")
    local svg_count=$(ls "${step}/logos/"*.svg 2>/dev/null | wc -l | tr -d ' ')

    local has_context="✗"
    local has_log="✗"

    if [ -f "${step}/context.md" ]; then
      local size=$(wc -c < "${step}/context.md" | tr -d ' ')
      [ "$size" -gt 200 ] && has_context="✓" || has_context="△ (テンプレートのみ)"
    fi

    if [ -f "${step}/log.md" ]; then
      local size=$(wc -c < "${step}/log.md" | tr -d ' ')
      [ "$size" -gt 300 ] && has_log="✓" || has_log="△ (テンプレートのみ)"
    fi

    echo "  ${step_name}/"
    echo "    context: ${has_context}"
    echo "    log:     ${has_log}"
    echo "    SVGs:    ${svg_count} files"

    if [ "$svg_count" -gt 0 ]; then
      echo "    logos:"
      for svg in "${step}/logos/"*.svg; do
        echo "      - $(basename "$svg")"
      done
    fi
    echo ""
  done

  # final ディレクトリ
  if [ -d "${dir}/final" ]; then
    local final_svgs=$(ls "${dir}/final/"*.svg 2>/dev/null | wc -l | tr -d ' ')
    echo "  final/"
    echo "    SVGs:   ${final_svgs} files"
    [ -f "${dir}/final/report.md" ] && echo "    report: ✓" || echo "    report: ✗"
  fi
}

if [ $# -ge 1 ]; then
  show_project "$1"
else
  if [ ! -d "$BASE_DIR" ]; then
    echo "No logo-design projects found."
    echo "Run: bash scripts/init.sh <project-name>"
    exit 0
  fi

  projects=($(ls -d "${BASE_DIR}"/*/ 2>/dev/null || true))
  if [ ${#projects[@]} -eq 0 ]; then
    echo "No logo-design projects found."
    exit 0
  fi

  echo ""
  echo "  Logo Design Projects"
  echo ""

  for proj in "${projects[@]}"; do
    show_project "$proj"
    echo ""
  done
fi
