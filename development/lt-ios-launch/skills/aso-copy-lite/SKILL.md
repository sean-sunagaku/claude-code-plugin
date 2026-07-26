---
name: aso-copy-lite
description: Produce a truthful Japanese App Store metadata pack and app-name shortlist in twelve minutes without a multi-agent research round. Use for a live launch sprint, fallback ASO copy, app naming under a hard deadline, or when local product evidence is available but market research is intentionally deferred.
---

# ASO Copy Lite

Optimize for a coherent positioning hypothesis, not an unverified ranking claim.

## Create the pack

Read the frozen requirements and produce `deliverables/aso-ja.md` containing:

- three app-name candidates with rationale;
- selected name;
- App Store name, at most 30 characters;
- subtitle, at most 30 characters;
- comma-separated keyword field, at most 100 characters, with no duplicated name/subtitle terms;
- promotional text, at most 170 characters;
- description with the value in the first three lines;
- category recommendation;
- screenshot headlines;
- one A/B positioning alternative;
- assumptions that require later keyword research.

Count characters programmatically. Mark every limit as `PASS` or `FAIL`.

## Guardrails

- Do not claim medical, eyesight, cognitive, ranking, popularity, or price benefits without evidence.
- Do not use “無料” unless distribution terms are known.
- Distinguish a game from medical vision testing.
- Keep the live version Japanese-only; localize after the demo.
- Prefer plain search language over clever wording.

Use [references/output-template.md](references/output-template.md).
