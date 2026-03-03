#!/bin/bash
# PostToolUse Hook: Detect common UI layout bugs in .tsx files
# Checks for fixed positioning without createPortal, z-index conflicts, etc.
# Output: exit 2 + stderr when issues found (feeds back to main conversation)

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract file_path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Only process .tsx files
if [[ ! "$FILE_PATH" =~ \.tsx$ ]]; then
  exit 0
fi

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

WARNINGS=""

# Check 1: fixed inset-0 or fixed + z-50 without createPortal
if grep -qE 'className.*fixed\s+inset-0|className.*fixed.*z-50' "$FILE_PATH"; then
  if ! grep -q 'createPortal' "$FILE_PATH"; then
    WARNINGS="${WARNINGS}[UI Pattern] CRITICAL: ${FILE_PATH} uses 'fixed inset-0' but does NOT use createPortal. Modal/dialog may be clipped by parent transform/overflow. Fix: import { createPortal } from 'react-dom' and wrap with createPortal(jsx, document.body)\n"
  fi
fi

# Check 2: fixed positioning inside a component that has relative/overflow parent indicators
if grep -qE 'className.*fixed' "$FILE_PATH"; then
  if grep -qE 'className.*relative.*overflow-hidden|className.*overflow-hidden.*relative' "$FILE_PATH"; then
    if ! grep -q 'createPortal' "$FILE_PATH"; then
      WARNINGS="${WARNINGS}[UI Pattern] WARNING: ${FILE_PATH} has both 'fixed' and 'relative overflow-hidden' classes. Fixed element may be clipped. Consider using createPortal.\n"
    fi
  fi
fi

# Feed back via exit 2 + stderr when issues found
if [ -n "$WARNINGS" ]; then
  echo -e "$WARNINGS" >&2
  exit 2
fi

exit 0
