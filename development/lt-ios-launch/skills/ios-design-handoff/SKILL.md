---
name: ios-design-handoff
description: Generate or review a Claude Design brief and convert its output into a deterministic SwiftUI implementation handoff with native iOS layout, tokens, states, transitions, and accessibility rules. Use for Claude Design mobile prototypes, three-screen iOS concepts, Design-to-Claude-Code handoffs, or when a visual prototype must be buildable without interpretation.
---

# iOS Design Handoff

Use the frozen requirements as the source of truth. Do not let visual exploration expand product scope.

## Prepare Claude Design

1. Attach the requirements file.
2. Choose `Mobile app design`.
3. Attach `Interactive prototype`, `Wireframe`, and this skill.
4. Select the live-demo iOS design system.
5. Use the prompt in [references/claude-design-prompt.md](references/claude-design-prompt.md).

## Enforce native iOS rules

- Design for a 393 × 852 pt viewport and safe areas.
- Use SF Pro, Dynamic Type semantics, an 8 pt spacing grid, and 44 × 44 pt minimum targets.
- Prefer `NavigationStack`, `Button`, `ProgressView`, `LazyVGrid`, sheets, and standard haptics.
- Avoid web navigation, tiny controls, hover-only states, ornamental cards, remote assets, and effects requiring third-party libraries.
- Keep motion reproducible with `withAnimation`, symbol effects, or standard transitions.
- Never convey correctness, error, or urgency by color alone.

## Extract the handoff

Write `deliverables/design-handoff.md` with:

1. screen inventory and navigation graph;
2. component tree per screen;
3. every visible string;
4. layout measurements and safe-area behavior;
5. semantic color, type, radius, spacing, and motion tokens;
6. normal, pressed, correct, incorrect, timeout, best-score, and reduced-motion states;
7. SwiftUI mapping for each component;
8. asset list with a local/system substitute;
9. implementation acceptance checks.

Use the contract in [references/handoff-contract.md](references/handoff-contract.md). Resolve missing values before coding; do not write “match the mockup.”

## Handoff gate

Pass only when each design element maps to a SwiftUI primitive or a small local custom view, and all interactions map to explicit state transitions.
