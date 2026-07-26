---
name: promo-video-lite
description: Render a deterministic 15-second vertical promo video from real Simulator screenshots with a three-beat viewer challenge and no Remotion initialization. Use in a twelve-minute parallel launch lane, as a reliable fallback to a richer Claude Design animation, or whenever ffmpeg and ImageMagick are available.
---

# Promo Video Lite

Prefer a finished, truthful video over a complex unfinished composition.

## Inputs

Use a Play capture and a Result capture from `deliverables/screenshots/raw/`.

## Render

Run:

```bash
"${CLAUDE_SKILL_DIR}/scripts/render-promo.sh" \
  deliverables/screenshots/raw/play.png \
  deliverables/screenshots/raw/result.png \
  deliverables/promo/irochigai-promo.mp4
```

The script creates three five-second beats:

1. show the puzzle: `1マスだけ、違う。`;
2. invite participation: `あなたは見つけられる？`;
3. reveal the result and product name.

Use no fabricated phone recording, user quote, rating, or sound claim. Audio is optional; silence is acceptable for social autoplay.

## Validate

Use `ffprobe` to verify 1080 × 1920, H.264, approximately 15 seconds, and a broadly compatible pixel format. Inspect frames near 1 s, 6 s, and 12 s.

See [references/storyboard.md](references/storyboard.md).
