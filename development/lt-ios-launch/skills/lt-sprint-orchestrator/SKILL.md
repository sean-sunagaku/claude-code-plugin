---
name: lt-sprint-orchestrator
description: Timebox and coordinate a live three-lane iOS launch sprint from audience idea to tested SwiftUI app, landing page, ASO copy, screenshots, promo video, and privacy report. Use for a 50-minute talk, demo rehearsal, fallback drill, or any request to finish a tiny local iOS product under a hard deadline.
---

# LT Sprint Orchestrator

Run the sprint to a clock. Optimize for a complete, demonstrable bundle rather than depth in any one artifact.

## Preflight

Finish these checks before starting the public clock:

1. Confirm Xcode, `xcodegen`, `xcrun simctl`, `ffmpeg`, and ImageMagick.
2. Confirm one booted iPhone Simulator and record its UDID.
3. Confirm the fallback requirements, Design output, and buildable repository.
4. Confirm `security-guidance@claude-plugins-official` is enabled.
5. Confirm all required permissions and first-run dialogs have already been handled.
6. Create `deliverables/status.log` and `deliverables/run-log.md`.

If any preflight check fails, fix it before the talk or explicitly mark the fallback.

## Run the 50-minute clock

Follow [references/timeline.md](references/timeline.md). Keep one visible lane status:

```text
A APP     requirements → Design → handoff → build → Simulator
B LAUNCH  LP | ASO | promo video
C PROOF   screenshots | privacy/security
```

Append each transition and completion to `deliverables/status.log` as:

```text
[mm:ss] LANE STATUS artifact-or-blocker
```

Use `terminal-notifier` when available for lane completion. Never wait silently for a build.

## Apply the scope lock

At minute 8, freeze:

- one persona and one job-to-be-done;
- no more than three screens;
- one local persistence primitive at most;
- no login, network, payment, authentication, or external SDK;
- one visual direction;
- one primary success metric.

After the lock, accept only bug fixes or removals. Treat additions as post-demo backlog.

## Apply fallback gates

- By minute 8: if requirements are not frozen, use the fallback requirements.
- By minute 20: if Design has no usable handoff, use the fallback Design bundle.
- By minute 28: if the project has not completed one build, switch to the fallback repository.
- By minute 43: if real screenshots are unavailable, use Design exports and label them as prototype images.
- By minute 46: if promo rendering is not complete, show the storyboard and pre-rendered fallback.

Record every fallback decision in `deliverables/run-log.md`; do not conceal it.

## Completion contract

Finish only when these paths exist and are readable:

- buildable iOS project;
- `deliverables/requirements.md`;
- `deliverables/design-handoff.md`;
- `lp/`;
- `deliverables/aso-ja.md`;
- `deliverables/screenshots/`;
- `deliverables/promo/irochigai-promo.mp4`;
- `deliverables/privacy-report.md`;
- `deliverables/run-log.md`.

Summarize actual duration, fallbacks, and remaining risks at the end.
