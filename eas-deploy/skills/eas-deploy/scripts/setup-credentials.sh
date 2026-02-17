#!/bin/bash
# ==============================================================
# EAS Credentials Setup - App ID + Certificate + Provisioning
# ==============================================================
# Usage:
#   bash setup-credentials.sh                    # auto-detect
#   bash setup-credentials.sh ./mobile           # specify project dir
#   bash setup-credentials.sh ./mobile android   # specify platform
#
# Environment variables (optional override):
#   EAS_PLATFORM    - ios | android (default: ios)
#   BUNDLE_ID       - override auto-detected bundleIdentifier
#   SKIP_CHECKS     - set "1" to skip prerequisite checks
#
# Non-interactive mode:
#   When stdin is not a terminal (e.g. piped from Claude Code),
#   the script runs all checks automatically and outputs the
#   command to run in an interactive terminal.
# ==============================================================
set -euo pipefail

# --- Config ---
PROJECT_DIR="${1:-.}"
PLATFORM="${2:-${EAS_PLATFORM:-ios}}"
IS_INTERACTIVE=true
[ -t 0 ] || IS_INTERACTIVE=false

# --- Auto-detect project root ---
find_project_root() {
  local dir="$1"
  if [ -f "$dir/eas.json" ]; then echo "$dir"; return; fi
  for sub in mobile app frontend; do
    if [ -f "$dir/$sub/eas.json" ]; then echo "$dir/$sub"; return; fi
  done
  echo ""
}

RESOLVED_DIR=$(find_project_root "$PROJECT_DIR")
if [ -z "$RESOLVED_DIR" ]; then
  echo "ERROR: eas.json not found in '$PROJECT_DIR' or its subdirectories (mobile/, app/, frontend/)"
  echo "Usage: bash setup-credentials.sh <project-dir> [ios|android]"
  exit 1
fi
RESOLVED_DIR=$(cd "$RESOLVED_DIR" && pwd)

echo "=== EAS Credentials Setup ==="
echo "Project:  $RESOLVED_DIR"
echo "Platform: $PLATFORM"
echo "Mode:     $( $IS_INTERACTIVE && echo 'interactive' || echo 'non-interactive (check only)' )"
echo ""

# --- Track issues found ---
ISSUES=()
FIXES=()

# --- Prerequisite checks ---
if [ "${SKIP_CHECKS:-0}" != "1" ]; then
  # eas-cli
  if ! command -v eas &>/dev/null; then
    ISSUES+=("eas-cli not found")
    FIXES+=("npm install -g eas-cli")
  else
    echo "[ok] eas-cli: $(eas --version 2>/dev/null | head -1)"
  fi

  # Login
  EAS_USER=$(eas whoami 2>/dev/null || true)
  if [ -z "$EAS_USER" ]; then
    ISSUES+=("Not logged in to EAS")
    FIXES+=("eas login")
  else
    echo "[ok] Account: $EAS_USER"
  fi
fi

# --- Detect Bundle ID / Package Name ---
detect_bundle_id() {
  local dir="$1"
  local id=""
  local config_file=""

  # Try app.config.ts, app.config.js, then app.json
  for f in "$dir/app.config.ts" "$dir/app.config.js" "$dir/app.json"; do
    [ -f "$f" ] && config_file="$f" && break
  done
  [ -z "$config_file" ] && echo "" && return

  if [ "$PLATFORM" = "ios" ]; then
    # TS/JS format: bundleIdentifier: "value" or bundleIdentifier: 'value'
    id=$(grep -oE "bundleIdentifier[\"']?\s*[:=]\s*[\"'][^\"']+[\"']" "$config_file" 2>/dev/null \
      | head -1 | sed "s/.*[\"']\([^\"']*\)[\"']$/\1/" || true)
    # JSON format fallback: "bundleIdentifier": "value"
    if [ -z "$id" ]; then
      id=$(grep -oE '"bundleIdentifier"\s*:\s*"[^"]*"' "$dir/app.json" 2>/dev/null \
        | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)
    fi
  else
    # Android: package: "value" or "package": "value"
    id=$(grep -oE "package[\"']?\s*[:=]\s*[\"'][^\"']+[\"']" "$config_file" 2>/dev/null \
      | head -1 | sed "s/.*[\"']\([^\"']*\)[\"']$/\1/" || true)
    if [ -z "$id" ]; then
      id=$(grep -oE '"package"\s*:\s*"[^"]*"' "$dir/app.json" 2>/dev/null \
        | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)
    fi
  fi

  echo "$id"
}

DETECTED_ID="${BUNDLE_ID:-$(detect_bundle_id "$RESOLVED_DIR")}"
if [ -z "$DETECTED_ID" ]; then
  ISSUES+=("Could not detect bundle identifier")
  FIXES+=("Add bundleIdentifier to app.config.ts or set BUNDLE_ID env var")
else
  echo "[ok] Bundle ID: $DETECTED_ID"
fi

# --- App name ---
APP_NAME=""
for f in "$RESOLVED_DIR/app.config.ts" "$RESOLVED_DIR/app.config.js" "$RESOLVED_DIR/app.json"; do
  if [ -f "$f" ]; then
    APP_NAME=$(grep -oE "name[\"']?\s*[:=]\s*[\"'][^\"']+[\"']" "$f" 2>/dev/null \
      | head -1 | sed "s/.*[\"']\([^\"']*\)[\"']$/\1/" || true)
    [ -n "$APP_NAME" ] && break
  fi
done
[ -n "$APP_NAME" ] && echo "[ok] App name: $APP_NAME"

# --- Check EAS project linked ---
check_eas_project() {
  local dir="$1"
  # Check for extra.eas.projectId in config files
  for f in "$dir/app.config.ts" "$dir/app.config.js" "$dir/app.json"; do
    if [ -f "$f" ] && grep -q "projectId" "$f" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# --- Auto-fix: eas init (Apple ID 不要なので非対話でも実行可能) ---
EAS_PROJECT_LINKED=false
if check_eas_project "$RESOLVED_DIR"; then
  echo "[ok] EAS project linked"
  EAS_PROJECT_LINKED=true
else
  echo "[..] EAS project not linked - running eas init..."
  cd "$RESOLVED_DIR"
  if eas init --non-interactive 2>/dev/null || yes | eas init 2>/dev/null; then
    echo "[ok] EAS project linked (auto-created)"
    EAS_PROJECT_LINKED=true
  else
    ISSUES+=("EAS project linking failed")
    FIXES+=("cd $RESOLVED_DIR && eas init")
  fi
fi

# --- Report issues ---
echo ""
if [ ${#ISSUES[@]} -gt 0 ]; then
  echo "=== Issues Found: ${#ISSUES[@]} ==="
  for i in "${!ISSUES[@]}"; do
    echo "  [!] ${ISSUES[$i]}"
    echo "      Fix: ${FIXES[$i]}"
  done
  echo ""

  # Output commands to run
  echo "=== Action Required ==="
  echo "Run the following in your terminal:"
  echo ""
  echo "  cd $RESOLVED_DIR"
  for fix in "${FIXES[@]}"; do
    echo "  $fix"
  done
  if [ -n "$DETECTED_ID" ]; then
    echo "  eas credentials --platform $PLATFORM"
  fi
  echo ""
  exit 1
fi

# --- Ready to execute ---
echo "--- Will set up ---"
echo "  1. Register App ID ($DETECTED_ID)"
echo "  2. Create Distribution Certificate"
echo "  3. Create Provisioning Profile"
echo "---"
echo ""

INTERACTIVE_GUIDE=$(cat <<'GUIDE'
=== 操作ガイド ===
Apple ID でログイン後、以下の順に選択してください:

  1. Which build profile?     → production
  2. What do you want to do?  → Build Credentials
  3. Distribution Certificate → Set up a new one (または既存を選択)
  4. Provisioning Profile     → Set up a new one (または既存を選択)

※ Apple ID + 2FA コード (6桁) の入力が必要です
GUIDE
)

if ! $IS_INTERACTIVE; then
  echo "=== All Checks Passed ==="
  echo ""
  echo "$INTERACTIVE_GUIDE"
  echo ""
  echo "=== Run in your terminal ==="
  echo ""
  echo "  cd $RESOLVED_DIR && eas credentials --platform $PLATFORM"
  echo ""
  exit 0
fi

# --- Execute (interactive only) ---
echo "$INTERACTIVE_GUIDE"
echo ""
cd "$RESOLVED_DIR"
eas credentials --platform "$PLATFORM"

# --- Result ---
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Credentials configured for: $DETECTED_ID ($PLATFORM)"
echo ""
echo "Next steps:"
echo "  eas build --platform $PLATFORM --profile development   # dev build"
echo "  eas build --platform $PLATFORM --profile production    # production build"
