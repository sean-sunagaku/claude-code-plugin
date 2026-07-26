---
name: product-sparring-lite
description: Pressure-test and freeze a tiny iOS MVP in seven minutes using one persona, one explicit devil's-advocate round, scope cuts, and a three-screen flow. Use when an audience supplies an app idea, when requirements must be settled live, or when a concept needs a fast implementation-risk check before Claude Design or Claude Code.
---

# Product Sparring Lite

Produce a decision, not a brainstorm archive. Read any supplied brief first and avoid questions already answered there.

## Seven-minute protocol

### 0:00–1:00 — Frame

State:

- one primary persona;
- one job-to-be-done;
- the moment of value;
- the non-negotiable constraints.

Ask at most two questions, and only when the answer changes the product.

### 1:00–3:00 — Attack once

Present one compact devil's-advocate block containing the four strongest failure modes:

1. the interaction can be gamed or spammed;
2. accessibility excludes a meaningful group;
3. the proposed screen count or data model is too large;
4. the experience lacks a reason to replay or return.

For each, state severity and the cheapest mitigation. Do not start a second debate round.

### 3:00–5:00 — Cut

Rank features as `must`, `later`, or `never in live demo`. Enforce:

- three screens maximum;
- no network, account, payment, or external API;
- one persistence record/primitive at most; a record may contain only the minimum fields needed for the frozen rules;
- one game loop or task loop;
- one visual direction.

### 5:00–7:00 — Freeze

Write `deliverables/requirements.md` using [references/requirements-template.md](references/requirements-template.md). Include a Mermaid state flow and acceptance tests.

Define:

- what counts as a screen (alerts and sheets are states unless they create a distinct task);
- the app's local-day/time-zone rule when the task is date-based;
- deterministic demo launch arguments or a reset procedure for one-shot, daily, or persisted flows;
- the meaning of success, failure, timeout, penalty, and reset for non-game tasks. Use `not applicable` only with a reason.

End with:

```text
SCOPE LOCKED — additions go to backlog; only fixes or cuts are allowed.
```

## Quality gate

Reject the result unless a SwiftUI developer can implement it without inventing:

- screen names and transitions;
- success, failure, timeout, and reset behavior;
- persistence;
- accessibility behavior;
- exact out-of-scope items.
