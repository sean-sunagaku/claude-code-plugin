---
name: ios-privacy-scan
description: Produce a visible, evidence-backed privacy and security report for a local iOS app by scanning permission declarations, network code, dependencies, persistence, and risky APIs, while complementing the official Claude Code security-guidance plugin. Use after implementation, in a live security lane, or before claiming that an app is offline and account-free.
---

# iOS Privacy Scan

Treat the official `security-guidance@claude-plugins-official` plugin as an edit-time guardrail, not as proof that the app is private.

## Scan

Confirm the official plugin is enabled, then run:

```bash
"${CLAUDE_SKILL_DIR}/scripts/scan-ios-privacy.sh" \
  <project-root> deliverables/privacy-report.md
```

Review every match. A zero count is meaningful only when the scan included all project Swift and plist files.

## Report

The report must state:

- permission usage-description keys;
- network clients, URL literals, and web views;
- external package/dependency declarations;
- persistence APIs and stored keys;
- required-reason API coverage when `UserDefaults` or `@AppStorage` appears;
- keychain, pasteboard, camera, microphone, location, contacts, and tracking APIs;
- limitations of static analysis;
- exact evidence for any “offline,” “no account,” or “no permission” claim.

Do not report `PASS` when files were missing or the build target was not identified.
Treat `UserDefaults` / `@AppStorage` without a target privacy manifest, the UserDefaults accessed-API category, and an accessed-API reasons key as an App Store blocker. The script can confirm declaration shape, but the reviewer must verify that the chosen Apple-approved reason matches the actual access boundary.

Use [references/interpretation.md](references/interpretation.md) when classifying results.
