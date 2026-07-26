---
name: launch-lp-lite
description: Build a polished local launch page in twelve minutes from a frozen app brief and design handoff, including a playable micro-demo, responsive copy, privacy proof, and zero remote dependencies. Use for the parallel marketing lane of a live iOS build, a fallback landing page, or a fast product teaser that must run offline.
---

# Launch LP Lite

Create a static, local-first site under `lp/`. Do not initialize a framework unless one already exists.

## Build

1. Read the frozen requirements and design handoff.
2. Create `lp/index.html`, `lp/styles.css`, and `lp/app.js`.
3. Use the same semantic tokens and copy as the app.
4. Put a playable grid in the hero so visitors experience the premise before download.
5. Include only:
   - one-line promise;
   - interactive demo;
   - three concise benefits;
   - privacy proof;
   - disabled or clearly labeled prelaunch CTA.
6. Use no external font, image, analytics, CDN, API, cookie, or build step.

## Quality gate

- Keep the first viewport understandable in five seconds.
- Make keyboard and touch interactions work.
- Respect `prefers-reduced-motion`.
- Avoid fabricated ratings, awards, testimonials, download counts, or health claims.
- Verify at mobile and desktop widths.
- Record the command and result in `deliverables/run-log.md`.

See [references/copy-contract.md](references/copy-contract.md) for the required copy hierarchy.
