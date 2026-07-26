---
name: simulator-screenshots
description: Capture reproducible screenshots from the currently booted iOS Simulator and turn them into three App Store marketing cards with validated dimensions and concise copy. Use after a successful Simulator build, during the two-minute proof lane, or when replacing prototype images with real app captures.
---

# Simulator Screenshots

Use actual Simulator pixels whenever the app builds.

## Capture

1. Determine the booted device and launch the target bundle. If more than one Simulator is booted, export the exact target as `SCREENSHOT_SIMULATOR_UDID`; the script intentionally refuses to guess.
2. Put the app into one deterministic state at a time: Home, Play, Result.
3. Run:

```bash
export SCREENSHOT_SIMULATOR_UDID=<recorded-preflight-udid>
"${CLAUDE_SKILL_DIR}/scripts/capture-simulator-shot.sh" home deliverables/screenshots/raw
"${CLAUDE_SKILL_DIR}/scripts/capture-simulator-shot.sh" play deliverables/screenshots/raw
"${CLAUDE_SKILL_DIR}/scripts/capture-simulator-shot.sh" result deliverables/screenshots/raw
```

Do not capture debug overlays, pointer indicators, permission dialogs, or personal notifications.

## Compose

Run:

```bash
"${CLAUDE_SKILL_DIR}/scripts/compose-store-card.sh" \
  <raw.png> <headline> <subheadline> <output.png>
```

Create exactly three cards:

1. `1マスだけ、違う。`
2. `到達レベルが、そのままスコア。`
3. `通信なし。アカウント不要。`

Do not imply eyesight/cognitive measurement, diagnosis, training, or improvement. Avoid absolute accessibility claims such as “誰でも遊べる”; state only behavior verified in the app.

## Validate

Check dimensions, legibility, clipping, truthful copy, and visual consistency using [references/checklist.md](references/checklist.md). Keep raw captures beside marketing cards.
